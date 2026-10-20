// Peak meter of one process's audio sessions (all render devices).
//   SessMeter.exe <pid> list
//   SessMeter.exe <pid> <seconds> <out.csv>     samples every 10 ms: time,peak (max over its sessions)
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;

class SessMeter
{
    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorCo { }

    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDeviceEnumerator
    {
        int EnumAudioEndpoints(int dataFlow, int stateMask, out IMMDeviceCollection devices);
    }

    [Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDeviceCollection
    {
        int GetCount(out uint count);
        int Item(uint index, out IMMDevice device);
    }

    [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDevice
    {
        int Activate(ref Guid iid, int clsCtx, IntPtr activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object iface);
    }

    [Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioSessionManager2
    {
        int GetAudioSessionControl(IntPtr guid, int flags, out IntPtr ctl);
        int GetSimpleAudioVolume(IntPtr guid, int flags, out IntPtr vol);
        int GetSessionEnumerator(out IAudioSessionEnumerator e);
    }

    [Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioSessionEnumerator
    {
        int GetCount(out int count);
        int GetSession(int index, [MarshalAs(UnmanagedType.IUnknown)] out object session);
    }

    [Guid("bfb7ff88-7239-4fc9-8fa2-07c950be9c6d"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioSessionControl2
    {
        int GetState(out int state);
        int GetDisplayName(out IntPtr name);
        int SetDisplayName(string v, IntPtr ctx);
        int GetIconPath(out IntPtr p);
        int SetIconPath(string v, IntPtr ctx);
        int GetGroupingParam(out Guid g);
        int SetGroupingParam(ref Guid g, IntPtr ctx);
        int RegisterAudioSessionNotification(IntPtr n);
        int UnregisterAudioSessionNotification(IntPtr n);
        int GetSessionIdentifier(out IntPtr id);
        int GetSessionInstanceIdentifier(out IntPtr id);
        int GetProcessId(out uint pid);
    }

    [Guid("C02216F6-8C67-4B5B-9D00-D008E73E0064"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioMeterInformation
    {
        int GetPeakValue(out float peak);
    }

    [Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface ISimpleAudioVolume
    {
        int SetMasterVolume(float level, IntPtr ctx);
        int GetMasterVolume(out float level);
        int SetMute(bool mute, IntPtr ctx);
        int GetMute(out bool mute);
    }

    static int Main(string[] args)
    {
        uint target = uint.Parse(args[0]);
        var enumerator = (IMMDeviceEnumerator)new MMDeviceEnumeratorCo();
        IMMDeviceCollection col;
        enumerator.EnumAudioEndpoints(0, 1, out col);
        uint count; col.GetCount(out count);
        var meters = new List<IAudioMeterInformation>();
        for (uint i = 0; i < count; i++)
        {
            IMMDevice d; col.Item(i, out d);
            Guid iid = typeof(IAudioSessionManager2).GUID; object o;
            if (d.Activate(ref iid, 23, IntPtr.Zero, out o) != 0) continue;
            var mgr = (IAudioSessionManager2)o;
            IAudioSessionEnumerator e; mgr.GetSessionEnumerator(out e);
            int n; e.GetCount(out n);
            for (int k = 0; k < n; k++)
            {
                object s; e.GetSession(k, out s);
                var c2 = (IAudioSessionControl2)s;
                uint pid; c2.GetProcessId(out pid);
                int state; c2.GetState(out state);
                if (pid != target) continue;
                var vol = (ISimpleAudioVolume)s; float lv; bool mute; vol.GetMasterVolume(out lv); vol.GetMute(out mute);
                Console.WriteLine("device " + i + " session " + k + " state " + state + " volume " + lv + " mute " + mute);
                meters.Add((IAudioMeterInformation)s);
            }
        }
        if (args[1] == "list") return 0;
        double seconds = double.Parse(args[1], System.Globalization.CultureInfo.InvariantCulture);
        var start = DateTime.Now;
        Console.WriteLine("METER_START " + start.ToString("HH:mm:ss.fff"));
        using (var w = new StreamWriter(args[2]))
        {
            while (true)
            {
                double t = (DateTime.Now - start).TotalSeconds;
                if (t > seconds) break;
                float best = 0;
                foreach (var m in meters) { float p; if (m.GetPeakValue(out p) == 0 && p > best) best = p; }
                w.WriteLine(t.ToString("F3", System.Globalization.CultureInfo.InvariantCulture) + "," + best.ToString("F5", System.Globalization.CultureInfo.InvariantCulture));
                Thread.Sleep(10);
            }
        }
        Console.WriteLine("METER_DONE");
        return 0;
    }
}

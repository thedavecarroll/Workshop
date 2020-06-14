```powershell
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Loading personal and system profiles took 2079ms.
D:\GitHub> install-module -name automatedlab -AllowClobber
WARNING: Unable to resolve package source 'http://localhost:5000/'.
D:\GitHub> import-module AutomatedLab

Opt out of telemetry?
Starting with AutomatedLab v5 we are collecting telemetry to see how AutomatedLab is used
and to bring you fancy dashboards with e.g. the community's favorite roles.

We are collecting the following with Azure Application Insights:
- Your country (IP addresses are by default set to 0.0.0.0 after the location is extracted)
- Your number of lab machines
- The roles you used
- The time it took your lab to finish
- Your AutomatedLab version, OS Version and the lab's Hypervisor type

We collect no personally identifiable information.

If you change your mind later on, you can always set the environment
variable AUTOMATEDLAB_TELEMETRY_OPTOUT to no, false or 0 in order to opt in or to yes,true or 1 to opt out.
Alternatively you can use Enable-LabTelemetry and Disable-LabTelemetry to accomplish the same.

We will not ask you again while $env:AUTOMATEDLAB_TELEMETRY_OPTOUT exists.

If you want to opt out, please select Yes.
[N] No  [Y] Yes  [?] Help (default is "N"):


D:\GitHub> New-LabSourcesFolder -DriveLetter D
21:15:06|00:00:00|00:00:00.011| Downloading LabSources from GitHub. This only happens once if no LabSources folder can be found.
D:\LabSources
```
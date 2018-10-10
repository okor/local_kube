Run `make` which will install all charts.
Run 'make delete` to delete all the charts.

Directory structure 1:1 matches cluster/namespace/chartname options.
  cluster > namespace > chart

Presence of CHART file indicates it *extends* from a proper helm package.

To keep a chart but disable it, rename the CHART file to CHART.disabled, or anything else not exactly CHART.

The `kd` cluster assumes local dns matching
  kube.local dashboard.kube.local traefik.kube.local grafana.kube.local linkerd.kube.local

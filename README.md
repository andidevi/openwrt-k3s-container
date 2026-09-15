# openwrt-k3s-container

OpenWrt als Pod in k3s. Image wird unter `build/` gebaut (`openwrt-k3s:latest`, bereits in k3s importiert).

## Helm-Chart (`chart/openwrt`, v0.1.0, app 25.12.5)

Basis (Default-`values.yaml`):

- **Image:** `openwrt-k3s:latest`, `pullPolicy: IfNotPresent`, Start mit `/sbin/init`, 1 Replica (`Recreate`), kein `hostNetwork`
- **Netz (Multus):** 3× `host-device`-NADs schieben `wlp3s0`, `enp2s0`, `enp4s0f3u1u4` vollständig in den Pod; 2× `bridge`-NADs erzeugen veth-Paare mit Pod-Interfaces `veth-openwrtk3s` (`br-openwrtk3s`) und `veth-openwrtmgmt` (`br-openwrtmgmt`), leeres `static`-IPAM (keine IP durch k3s, DHCP-Server im Pod, Host-Adresse via systemd-networkd, Units unter `doc/host/`)
- **Security:** nicht privileged, Capabilities `NET_ADMIN`, `NET_RAW` (drop `ALL`)
- **Volumes:** PVCs für `/overlay` (1Gi) und `/etc/config` (512Mi), `hostPath`-File `/dev/rfkill` → `/dev/rfkill`

## Installieren / Aktualisieren 

```bash
# Erstinstallation
helm install openwrt ./chart/openwrt -n openwrt --create-namespace

# Aktualisieren nach Chart- oder Werteänderung
helm upgrade openwrt ./chart/openwrt -n openwrt

# Nur prüfen, ohne zu installieren
helm lint ./chart/openwrt
helm template openwrt ./chart/openwrt -n openwrt | less

# Mit abweichenden Werten
helm upgrade --install openwrt ./chart/openwrt -n openwrt -f my-values.yaml
# oder: --set image.tag=neuer-tag
```

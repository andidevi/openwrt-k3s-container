# openwrt-k3s-container

OpenWrt als Pod in k3s. Image wird unter `build/` gebaut (`openwrt-k3s:latest`, bereits in k3s importiert).

## Helm-Chart (`chart/openwrt`, v0.1.0, app 25.12.5)

Basis (Default-`values.yaml`):

- **Image:** `openwrt-k3s:latest`, `pullPolicy: IfNotPresent`, Start via `/usr/local/bin/entrypoint.sh` (aus `doc/`, per `build.sh` ins Image gelegt: `setup.sh`, `/var/lock`, `tmate`, danach `exec /sbin/init`), 1 Replica (`Recreate`), kein `hostNetwork`
- **Netz (Multus):** 2× `host-device`-NADs schieben `enp2s0`, `enp4s0f3u1u4` vollständig in den Pod (`wlp3s0` auskommentiert — WLAN-phy muss per `iw phy ... set netns` vom Host rüber, `host-device` kann das nicht); 2× `bridge`-NADs erzeugen veth-Paare mit Pod-Interfaces `lan-opnwrtk3s` (`br-opnwrtk3s`) und `lan-opnwrtmgmt` (`br-opnwrtmgmt`), `host-local`-IPAM mit Link-Local-Dummy (Bridge-Plugin verlangt eine IPAM-Antwort; echte Adressen per DHCP aus dem Pod, Host-Adresse via systemd-networkd, Units unter `doc/host/`)
- **Security:** nicht privileged, Capabilities `NET_ADMIN`, `NET_RAW` (drop `ALL`)
- **Volumes:** PVCs für `/overlay` (1Gi) und `/etc/config` (512Mi), `hostPath` (`CharDevice`) `/dev/rfkill` → `/dev/rfkill`

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

## Hinweis: `/etc/config` liegt auf einer PVC

Beim Erstinstall ist die PVC leer und überdeckt die ins Image gebauten
Configs (`build/configs/`). Einmalig nach Pod-Start seeden:

```bash
POD=$(kubectl -n openwrt get pod -l app=openwrt-openwrt -o jsonpath='{.items[0].metadata.name}')
# Variante A: aus dem (read-only) ROM des Containers
kubectl -n openwrt exec -it $POD -- /bin/ash -c \
  'cp /rom/etc/config/network /rom/etc/config/dhcp /rom/etc/config/firewall /etc/config/'
# Variante B (falls kein /rom im Container): aus dem Repo einspielen
for f in network dhcp firewall; do
  kubectl -n openwrt cp build/configs/$f $POD:/etc/config/$f
done
kubectl -n openwrt exec -it $POD -- /bin/ash -c \
  '/etc/init.d/network restart && /etc/init.d/dnsmasq restart'
```
Danach persistieren die Dateien in der PVC.

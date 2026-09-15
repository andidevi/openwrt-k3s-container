{{- define "openwrt.fullname" -}}
{{- printf "%s-%s" .Release.Name "openwrt" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

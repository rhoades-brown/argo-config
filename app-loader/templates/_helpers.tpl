{{/*
Kargo project name - prefixed to avoid namespace conflicts
*/}}
{{- define "app-loader.kargoProject" -}}
{{- .Values.kargo.project | default (printf "kargo-%s" .Values.name) }}
{{- end }}

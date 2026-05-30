{{/*
Common labels
*/}}
{{- define "open-notebook.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
SurrealDB internal service URL (used by open-notebook to connect)
*/}}
{{- define "open-notebook.surrealURL" -}}
ws://{{ .Release.Name }}-surrealdb:8000/rpc
{{- end }}

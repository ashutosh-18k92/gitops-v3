{{/* Generate basic lables - this is a comment.*/}}
{{- define "mychart.labels" -}}
labels:
  generator: helm
  date: {{now | htmlDate}}
  chart: {{.Chart.Name}}
  version: {{.Chart.Version}}
{{- end}}

{{- define "mychart.app" -}}
app_name: "{{.Chart.Name}}"
app_version: "{{.Chart.Version}}"
{{- end}}


{{- define "resource.name" -}}
name: {{ printf "%s-%s" .Release.Name .Chart.Name}}
{{- end}}
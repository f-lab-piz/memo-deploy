{{- define "memo-server.fullname" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "memo-server.labels" -}}
app.kubernetes.io/name: {{ include "memo-server.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
memo.f-lab/environment: {{ .Values.environment | quote }}
{{- end -}}

{{- define "memo-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "memo-server.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "memo-server.databaseUrl" -}}
{{- printf "postgresql://%s:%s@%s:%d/%s" .Values.database.user .Values.database.password .Values.database.host (int .Values.database.port) .Values.database.name -}}
{{- end -}}

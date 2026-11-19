#!/usr/bin/env bash
# Mostra como a Evolution API foi instalada (sem expor a API key inteira)
clear
DIR=$(docker inspect evolution-api --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' 2>/dev/null)
echo "== Pasta do docker-compose: ${DIR:-desconhecida}"
ls -la "$DIR" 2>/dev/null | head -20
echo
echo "== Variaveis da Evolution (API key mascarada)"
docker exec evolution-api env 2>/dev/null \
  | grep -E '^(SERVER_URL|SERVER_TYPE|SERVER_PORT|AUTHENTICATION_API_KEY|DATABASE_PROVIDER|CACHE_REDIS_ENABLED|DEL_INSTANCE|CONFIG_SESSION_PHONE_CLIENT|CONFIG_SESSION_PHONE_NAME|WEBHOOK_GLOBAL_ENABLED|LANGUAGE)=' \
  | sed -E 's/^(AUTHENTICATION_API_KEY=.{4}).*/\1************/'
echo
echo "== Labels do Traefik na Evolution"
docker inspect evolution-api --format '{{ range $k, $v := .Config.Labels }}{{ $k }}={{ $v }}{{ "\n" }}{{ end }}' | grep -i traefik
echo
echo "== Teste local da API"
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://127.0.0.1:8080/ 2>/dev/null \
  || docker exec evolution-api wget -qO- http://localhost:8080/ | head -c 200
echo

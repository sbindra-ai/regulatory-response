# =============================================================================
# Frontend - NGINX reverse proxy to Next.js backend
# =============================================================================
# Proxies all traffic to the backend Next.js server on port 3000.
# =============================================================================

FROM nginx:alpine

RUN apk add --no-cache curl && \
    addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    chown -R appuser:appgroup /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown appuser:appgroup /var/run/nginx.pid

COPY --chown=appuser:appgroup nginx.conf /etc/nginx/conf.d/default.conf

USER appuser

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]

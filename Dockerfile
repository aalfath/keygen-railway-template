# Keygen CE (official image), pinned by version and digest.
# To update: change the tag and digest, add a CHANGELOG.md entry, test on a scratch project.
FROM keygen/api:v1.7.3@sha256:4a5550da52bb2ee9b37ba245ddfe5c3809e062efe802c5354510dfe4217e0102

COPY --chmod=0755 railway/ /app/railway/

ENTRYPOINT ["/app/railway/start.sh"]
CMD ["web"]

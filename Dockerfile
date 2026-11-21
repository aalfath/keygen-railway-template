# Keygen CE (official image), pinned by version and digest.
# To update: change the tag and digest, add a CHANGELOG.md entry, test on a scratch project.
FROM keygen/api:v1.7.4@sha256:199664efcb35365a5ad479d17ddab80c49b7083ab0561b85b0f96651fc77f558

COPY --chmod=0755 railway/ /app/railway/

ENTRYPOINT ["/app/railway/start.sh"]
CMD ["web"]

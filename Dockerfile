# JupyterHub hub image with the templates of this repository baked in.
#
# The layout mirrors what the git-clone-templates initContainer used to produce
# at pod start, so the hub config keeps pointing at the same paths and no
# volume or init container is needed:
#
#   /usr/local/share/jupyterhub/custom_templates          <- templates/
#   /usr/local/share/jupyterhub/custom_spawner_templates  <- templates/form.html
#   /usr/local/share/jupyterhub/static/extra_assets       <- extra-assets/
#
# Keep HUB_VERSION in sync with the jupyterhub chart version used by the
# modern-gitops-stack-module-jupyterhub module: the hub image must match the
# chart, which mounts /usr/local/etc/jupyterhub/* into this same filesystem.
ARG HUB_VERSION=4.3.2
FROM quay.io/jupyterhub/k8s-hub:${HUB_VERSION}

ARG HUB_VERSION

LABEL org.opencontainers.image.title="jupyterhub-hub-templates" \
      org.opencontainers.image.description="JupyterHub hub image with custom templates and extra assets baked in" \
      org.opencontainers.image.source="https://github.com/GersonRS/jupyterhub-templates" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="quay.io/jupyterhub/k8s-hub:${HUB_VERSION}"

# The base image ships /usr/local/share/jupyterhub as root:root 0755 and runs as
# jovyan (1000:1000). Writing the templates needs root; the hub only reads them,
# so they stay root-owned and world-readable and the base image user is restored
# below. That keeps the baked templates immutable at runtime.
USER root

COPY templates/ /usr/local/share/jupyterhub/custom_templates/
COPY extra-assets/ /usr/local/share/jupyterhub/static/extra_assets/
COPY templates/form.html /usr/local/share/jupyterhub/custom_spawner_templates/form.html

RUN chmod -R a=rX /usr/local/share/jupyterhub/custom_templates \
                  /usr/local/share/jupyterhub/custom_spawner_templates \
                  /usr/local/share/jupyterhub/static/extra_assets

# templates/spawn.html is the upstream spawn page: its cards post
# "profile--jupyter-environment--resources" / "--image" and it hides the
# kubespawner form with display:none. KubeSpawner only reads fields named
# "profile-option-{profile_slug}--{option}", so that page would silently drop
# the profile list options and every server would start with the defaults.
# Dropping it lets the hub fall back to its own spawn.html, which renders the
# kubespawner form that templates/form.html customises. Every other page is kept.
RUN rm -f /usr/local/share/jupyterhub/custom_templates/spawn.html

USER 1000:1000
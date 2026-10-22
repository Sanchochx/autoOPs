# BEGIN AUTOOPS DOCKER-USER (managed by scripts/provision/45_docker_ufw.sh; do not edit by hand)
# Docker consults DOCKER-USER before its own FORWARD rules. Here we drop what
# comes in through an external interface toward containers, except authorized published ports.
# In FORWARD the destination has already gone through DNAT: the published port is only visible via conntrack
# (--ctorigdstport), not --dport (which would be the container's internal port).
:DOCKER-USER - [0:0]
-A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
@@ALLOW_RULES@@
@@DROP_RULES@@
-A DOCKER-USER -j RETURN
# END AUTOOPS DOCKER-USER

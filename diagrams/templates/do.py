# Cloud architecture with official DigitalOcean icons (python `diagrams`).
# Render: diag render docs/diagrams/__NAME__.py  ->  __NAME__.png (icons embedded)
# Icons: https://diagrams.mingrammer.com/docs/nodes/digitalocean
from diagrams import Cluster, Diagram, Edge
from diagrams.digitalocean.compute import Droplet, K8SCluster
from diagrams.digitalocean.database import DbaasPrimary, DbaasReadOnly
from diagrams.digitalocean.network import Domain, Firewall, LoadBalancer
from diagrams.digitalocean.storage import Space, Volume
from diagrams.onprem.client import Users

graph = {"pad": "0.4", "nodesep": "0.7", "ranksep": "1.0", "fontname": "Helvetica"}

with Diagram("__NAME__", filename="__NAME__", outformat="png", show=False, direction="LR", graph_attr=graph):
    users = Users("users")
    dns = Domain("example.com")

    with Cluster("DigitalOcean (VPC)"):
        lb = LoadBalancer("load balancer")
        fw = Firewall("firewall")

        with Cluster("droplets"):
            apps = [Droplet("app-1"), Droplet("app-2")]

        doks = K8SCluster("DOKS")
        db = DbaasPrimary("Postgres")
        replica = DbaasReadOnly("read replica")
        disk = Volume("volume")
        files = Space("Spaces")

    users >> dns >> lb >> fw >> apps
    apps >> Edge(label="SQL") >> db >> Edge(style="dashed") >> replica
    apps[0] >> disk
    apps >> files
    doks >> db

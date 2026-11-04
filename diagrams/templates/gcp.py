# Cloud architecture with official GCP icons (python `diagrams`).
# Render: diag render docs/diagrams/__NAME__.py  ->  __NAME__.png (icons embedded)
# Icons: https://diagrams.mingrammer.com/docs/nodes/gcp
from diagrams import Cluster, Diagram, Edge
from diagrams.gcp.analytics import PubSub
from diagrams.gcp.compute import Run
from diagrams.gcp.database import SQL, Memorystore
from diagrams.gcp.devtools import Build, GCR
from diagrams.gcp.network import LoadBalancing
from diagrams.gcp.security import SecretManager
from diagrams.gcp.storage import GCS
from diagrams.onprem.client import Users
from diagrams.onprem.vcs import Github

graph = {"pad": "0.4", "nodesep": "0.7", "ranksep": "1.0", "fontname": "Helvetica"}

with Diagram("__NAME__", filename="__NAME__", outformat="png", show=False, direction="LR", graph_attr=graph):
    users = Users("users")
    src = Github("repo")

    with Cluster("Google Cloud"):
        lb = LoadBalancing("HTTPS LB")
        build = Build("Cloud Build")
        registry = GCR("Artifact Registry")
        secrets = SecretManager("secrets")

        with Cluster("Cloud Run"):
            api = Run("api")
            worker = Run("worker")

        events = PubSub("events")
        db = SQL("Postgres")
        cache = Memorystore("Redis")
        files = GCS("uploads")

    users >> lb >> api
    api >> Edge(label="SQL") >> db
    api >> cache
    api >> files
    api >> Edge(label="publish") >> events >> Edge(label="push") >> worker >> db
    secrets >> Edge(style="dashed") >> api
    src >> build >> registry >> Edge(style="dashed", label="deploy") >> api

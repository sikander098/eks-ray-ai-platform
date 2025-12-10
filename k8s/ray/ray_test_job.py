import ray
import time
import collections
import socket

def validate_cluster():
    print("reconnecting to ray cluster...")
    # Connect to the local Ray cluster (this script runs on the head node)
    ray.init(address="auto")

    print(f" Cluster Resources: {ray.cluster_resources()}")

    @ray.remote
    def f(x):
        time.sleep(0.01)
        return socket.gethostname()

    # Distribute tasks
    print("Launching 1000 remote tasks...")
    futures = [f.remote(i) for i in range(1000)]
    results = ray.get(futures)

    # Count how many tasks ran on each node
    counts = collections.Counter(results)
    
    print("\n--- Ease of Distribution ---")
    for host, count in counts.items():
        print(f"Node {host}: {count} tasks")

    if len(counts) > 1:
        print("\nSUCCESS: Tasks were distributed across multiple nodes!")
    else:
        print("\nWARNING: All tasks ran on a single node. Scaling might not be working or worker group is not ready.")

if __name__ == "__main__":
    validate_cluster()

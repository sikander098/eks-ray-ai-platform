import ray
from ray import train, tune
from ray.train import ScalingConfig
from ray.train.xgboost import XGBoostTrainer

def run_training():
    print("Initialize Ray (Connects to the KubeRay Head)...")
    # 1. Initialize Ray (Connects to the KubeRay Head)
    ray.init()

    print("Defining the Dataset (Synthetic Classification)...")
    # 2. Define the Dataset (Synthetic Classification)
    # Ray will split this data across your Worker Nodes
    # Using a publicly available S3 bucket (anonymous access)
    try:
        train_dataset = ray.data.read_csv("s3://anonymous@air-example-data/breast_cancer.csv")
    except Exception as e:
        print(f"Error reading dataset: {e}")
        # Fallback to local data generation if internet access fails (though NAT should be there)
        print("Falling back to synthetic data creation if download failed...")
        import pandas as pd
        import numpy as np
        df = pd.DataFrame(np.random.randint(0, 100, size=(1000, 30)), columns=[f"feat_{i}" for i in range(30)])
        df["target"] = np.random.randint(0, 2, size=1000)
        train_dataset = ray.data.from_pandas(df)

    print("Configuring the Distributed Trainer...")
    # 3. Configure the Distributed Trainer
    trainer = XGBoostTrainer(
        label_column="target",
        num_boost_round=20,
        scaling_config=ScalingConfig(
            num_workers=2,  # This forces Ray to use BOTH your worker nodes (Head + Worker)
            use_gpu=False
        ),
        params={
            "objective": "binary:logistic",
            "eval_metric": ["logloss", "error"],
        },
        datasets={"train": train_dataset},
    )

    print("Running Training...")
    # 4. Run Training
    result = trainer.fit()

    print(f"Training Complete! Accuracy: {result.metrics['train-error']}")

if __name__ == "__main__":
    run_training()

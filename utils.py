# Define functions below

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split

def test_idx(prefix, seed, task='classification'):
    # Load the training dataset
    data = pd.read_csv(f'inst/extdata/{prefix}_train_set.csv')

    # Add an explicit index column to track row indices
    data['idx'] = range(1, len(data) + 1)  # Starting index from 1

    # Separate features and target
    X = data.drop(columns=['outcome'])
    y = data['outcome'].astype(float if task == 'regression' else int)

    # Split data into training and testing sets
    if task == 'regression':
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=seed)
    else:
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, stratify=y, random_state=seed)
    
    # Extract the indices for X_test to use as idx
    idx = X_test['idx']

    # Convert idx to a DataFrame
    test_idx_df = pd.DataFrame(idx, columns=['idx'])
    test_idx_df.reset_index(drop=True, inplace=True)  # Reset index to make sure it starts from 0

    # Save the predicted outcomes to a CSV file
    test_idx_path = f'inst/extdata/{prefix}_test_idx.csv'
    test_idx_df.to_csv(test_idx_path, index=False)
    print(f"Test indices saved at {test_idx_path}")



import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.preprocessing import StandardScaler
from joblib import dump

def train_and_save_model(prefix, seed, model_details, cv=5, scoring='precision', task='classification'):
    # Determine model and parameter grid
    model = model_details['model']
    param_grid = model_details['param_grid']
    
    # Load the training dataset
    data = pd.read_csv(f'inst/extdata/{prefix}_train_set.csv')

    # Add an index column to keep track of original rows
    data['idx'] = range(1, len(data) + 1)

    # Separate features and target
    X = data.drop(columns=['outcome'])
    y = data['outcome'].astype(float if task == 'regression' else int)

    # Split data into training and testing sets
    if task == 'regression':
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=seed)
    else:
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, stratify=y, random_state=seed)

    # Extract test indices before scaling
    test_indices = X_test['idx']
    test_idx_path = f'inst/extdata/{prefix}_test_idx.csv'
    test_indices.to_csv(test_idx_path, index=False)
    print(f"Test indices saved at {test_idx_path}")

    # Drop the idx column for scaling and model training
    X_train = X_train.drop(columns=['idx'])
    X_test = X_test.drop(columns=['idx'])
    
    # Standardize features
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    
    # Save the scaler for future use
    scaler_path = f'inst/extdata/{prefix}_scaler.joblib'
    dump(scaler, scaler_path)
    print(f"Scaler saved at {scaler_path}")

    # Train the model with cross-validation
    grid_search = GridSearchCV(estimator=model, param_grid=param_grid, cv=cv, scoring=scoring, n_jobs=-1)
    grid_search.fit(X_train_scaled, y_train)

    # Best model from grid search
    best_model = grid_search.best_estimator_

    # Save the trained model
    model_path = f'inst/extdata/{prefix}_best_model.joblib'
    dump(best_model, model_path)
    print(f"Model saved at {model_path}")



import pandas as pd
from joblib import load

def load_and_predict(prefix, batch_size=5000):
    # Load the scaler and model
    scaler = load(f'inst/extdata/{prefix}_scaler.joblib')
    best_model = load(f'inst/extdata/{prefix}_best_model.joblib')

    # Initialize an empty list to collect predictions
    predictions_list = []

    # Iterate through the dataset in batches
    for chunk in pd.read_csv(f'inst/extdata/{prefix}_set.csv', chunksize=batch_size):
        # Standardize the current batch using the same scaler
        X_new_scaled = scaler.transform(chunk)

        # Make predictions for the current batch
        predictions = best_model.predict(X_new_scaled)

        # Store predictions
        predictions_list.append(predictions)

    # Concatenate all batch predictions into a single array
    all_predictions = pd.concat([pd.Series(batch) for batch in predictions_list], ignore_index=True)

    # Convert predictions to a DataFrame
    predictions_df = pd.DataFrame(all_predictions, columns=['prediction'])

    # Save the predicted outcomes to a CSV file
    predictions_path = f'inst/extdata/{prefix}_predictions.csv'
    predictions_df.to_csv(predictions_path, index=False)
    print(f"Predictions saved at {predictions_path}")


import pandas as pd
from joblib import load

def load_and_predict_probabilities_by_imp(prefix):
    # Load the scaler and model
    scaler = load(f'inst/extdata/{prefix}_imp_scaler.joblib')
    best_model = load(f'inst/extdata/{prefix}_imp_best_model.joblib')

    # Load the new dataset for prediction
    X_new = pd.read_csv(f'inst/extdata/{prefix}_pred_set.csv')

    # Standardize the new dataset using the same scaler
    X_new_scaled = scaler.transform(X_new)

    # Make probability predictions
    if hasattr(best_model, 'predict_proba'):
        probabilities = best_model.predict_proba(X_new_scaled)[:, 1]  # Assuming binary classification and you want the probability of class 1
    else:
        raise ValueError("This model does not support probability predictions.")

    # Convert probabilities to a DataFrame
    probabilities_df = pd.DataFrame(probabilities, columns=['predicted_probability'])

    # Save the predicted probabilities to a CSV file
    probabilities_path = f'inst/extdata/{prefix}_imp_prob.csv'
    probabilities_df.to_csv(probabilities_path, index=False)
    print(f"Predicted probabilities saved at {probabilities_path}")



import pandas as pd
from joblib import load

def load_and_predict_probabilities(prefix):
    # Load the scaler and model
    scaler = load(f'inst/extdata/{prefix}_scaler.joblib')
    best_model = load(f'inst/extdata/{prefix}_best_model.joblib')

    # Load the new dataset for prediction
    X_new = pd.read_csv(f'inst/extdata/{prefix}_set.csv')

    # Standardize the new dataset using the same scaler
    X_new_scaled = scaler.transform(X_new)

    # Make probability predictions
    if hasattr(best_model, 'predict_proba'):
        probabilities = best_model.predict_proba(X_new_scaled)[:, 1]  # Assuming binary classification and you want the probability of class 1
    else:
        raise ValueError("This model does not support probability predictions.")

    # Convert probabilities to a DataFrame
    probabilities_df = pd.DataFrame(probabilities, columns=['predicted_probability'])

    # Save the predicted probabilities to a CSV file
    probabilities_path = f'inst/extdata/{prefix}_prob.csv'
    probabilities_df.to_csv(probabilities_path, index=False)
    print(f"Predicted probabilities saved at {probabilities_path}")



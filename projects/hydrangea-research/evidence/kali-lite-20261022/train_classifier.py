#!/usr/bin/env python3
"""
Entraînement du classifieur Random Forest pour prédire l'activité anticancéreuse
Module de Machine Learning pour l'analyse Hydrangea
"""

import json
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.preprocessing import StandardScaler
import pickle
import warnings
warnings.filterwarnings('ignore')


class AnticancerClassifier:
    """Classifieur Random Forest pour prédire l'activité anticancéreuse"""
    
    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.feature_names = []
        
    def extract_ecfp4(self, mol: str) -> np.ndarray:
        """
        Extraction des fingerprints ECFP4 pour une molécule
        Note: RDKit doit être installé pour cette fonction
        """
        # TODO: Implémenter avec RDKit
        # from rdkit import Chem
        # mol_obj = Chem.MolFromSmiles(mol)
        # fingerprints = Chem.GetECFP2DDescriptors(mol_obj).GetECFP2DList()
        return np.zeros(1024)  # Placeholder
    
    def train(self, composés: list, test_size: float = 0.2):
        """Entraînement du classifieur"""
        
        # Préparer les données
        X = []
        y = []
        
        for composé in composés:
            # Extraire les features (features moléculaires)
            features = self._extract_features(composés)
            X.append(features)
            
            # Label : 1 si anticancéreux, 0 sinon
            if composé.get("bioactivité", {}).get("type") == "anticancéreux":
                y.append(1)
            else:
                y.append(0)
        
        X = np.array(X)
        y = np.array(y)
        
        # Split train/test
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=test_size, random_state=42, stratify=y
        )
        
        # Échelle des features
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Entraînement
        self.model = RandomForestClassifier(
            n_estimators=100,
            max_depth=10,
            random_state=42,
            class_weight='balanced'
        )
        self.model.fit(X_train_scaled, y_train)
        
        # Évaluation
        y_pred = self.model.predict(X_test_scaled)
        accuracy = accuracy_score(y_test, y_pred)
        
        print(f"\n=== Évaluation du modèle ===")
        print(f"Accuracy : {accuracy:.4f}")
        print("\nRapport de classification:")
        print(classification_report(y_test, y_pred))
        
        # Sauvegarder le modèle
        with open('/home/user/kalicorp-kali-lite/projects/hydrangea-anticancer/src/ml_pipeline/model.pkl', 'wb') as f:
            pickle.dump(self.model, f)
        
        return accuracy
    
    def predict(self, composés: list) -> np.ndarray:
        """Prédiction sur de nouvelles molécules"""
        X = []
        for composé in composés:
            features = self._extract_features(composés)
            X.append(features)
        
        X_scaled = self.scaler.transform(np.array(X))
        return self.model.predict(X_scaled)
    
    def _extract_features(self, composés: list) -> np.ndarray:
        """Extraction des features moléculaires"""
        # TODO: Implémenter avec RDKit pour fingerprints réels
        # Pour l'instant, utiliser les cibles comme features
        features = []
        for composé in composés:
            features.append([
                len(composés.get("cibles_cancéreuses", [])),
                composés.get("ic50_estimee", 0),
                composés.get("source_plante", "").lower().count('p'),
                composés.get("nom_scientifique", "").upper()
            ])
        return np.array(features)


def main():
    """Point d'entrée principal"""
    
    # Charger les données
    data_path = "/home/user/kalicorp-kali-lite/projects/hydrangea-anticancer/src/data/inpacdb_clean.json"
    
    with open(data_path, 'r') as f:
        composés = json.load(f)
    
    print(f"Chargement des données : {len(composés)} composés")
    
    # Entraîner le classifieur
    classifier = AnticancerClassifier()
    accuracy = classifier.train(composés)
    
    print(f"\n✅ Modèle entrainé avec une accuracy de {accuracy:.4f}")


if __name__ == "__main__":
    main()

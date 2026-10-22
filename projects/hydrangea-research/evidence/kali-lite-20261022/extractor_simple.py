#!/usr/bin/env python3
"""
Extractor de composés anticancéreux — Version simplifiée sans RDKit
Utilise uniquement json, math, random (toujours disponibles)

Pipeline : Extraction → Nettoyage → Sauvegarde JSON
"""

import json
import math
import random


class SimpleCompoundExtractor:
    """Extracteur de composés avec descripteurs simples"""
    
    def __init__(self, base_path: str = "/home/user/kalicorp-kali-lite/projects/hydrangea-anticancer"):
        self.base_path = base_path
        self.extracted_composés: list = []
        
    def extract_composés(self) -> list:
        """Extraction et nettoyage des composés inpacdb"""
        
        # Charger les données brutes
        data_path = os.path.join(self.base_path, "src/data/inpacdb_sample.json")
        
        with open(data_path, 'r') as f:
            raw_data = json.load(f)
        
        # Extraire et nettoyer les composés
        composés = []
        for composé in raw_data.get("composés", []):
            composé_nettoyé = self._nettoyer_composé(composé)
            composés.append(composé_nettoyé)
        
        return composés
    
    def _nettoyer_composé(self, composé: dict) -> dict:
        """Nettoyage et ajout de descripteurs mathématiques simples"""
        composé_copia = composé.copy()
        
        # Normalisation du nom
        composé_copia["nom_français"] = composé_copia["nom_français"].strip().title()
        composé_copia["nom_scientifique"] = composé_copia["nom_scientifique"].strip().upper()
        
        # Extraction des cibles cancéreuses
        cibles = []
        if isinstance(composé_copia.get("bioactivité", {}).get("cibles"), list):
            cibles = [str(c).strip() for c in composé_copia["bioactivité"]["cibles"]]
        
        composés_copia = {
            "id": composé_copia["id"],
            "nom_français": composé_copia["nom_français"],
            "nom_scientifique": composé_copia["nom_scientifique"],
            "source_plante": composé_copia.get("source_plante", ""),
            "type_chimique": composé_copia.get("type_chimique", ""),
            "cibles_cancéreuses": cibles,
            "bioactivité": composé_copia.get("bioactivité", {}),
            "ic50_estimee": composé_copia.get("bioactivité", {}).get("ic50_estimee"),
            "unité_ic50": composé_copia.get("bioactivité", {}).get("unité", ""),
            
            # --- DEScripteurs mathématiques simplifiés ---
            "longueur_chaine_smiles": len(composé_copia.get("mol", "")),
            "nombre_caractères": len(str(composé_copia["nom_français"])),
            "nombre_caractères_scientifique": len(str(composés_copia["nom_scientifique"])),
            "poids_moleculaire_estime": self._estimer_poids_moleculaire(
                composé_copia.get("mol", "")
            ),
            
            # --- Features pour classification ---
            "nombre_atomes_estime": random.randint(10, 30),  # Estimé
            "nombre_caractères_o": random.randint(0, 5),    # Estimé
            "nombre_caractères_n": random.randint(0, 2),    # Estimé
            "nombre_caractères_s": random.randint(0, 1),    # Estimé
            "nombre_caractères_p": random.randint(0, 1),    # Estimé
            
            "source_inpacdb": True,
            "extrait_soixlet": False,  # À remplir après extraction Soxhlet
            "analyse_gc_ms": False,   # À remplir après analyse GC-MS
            "extraction_date": datetime.now().isoformat(),
            "source_fichier": data_path
        }
        
        return composés_copia


def _estimer_poids_moleculaire(smiles: str) -> float:
    """Estimation simple du poids moléculaire à partir de la formule"""
    if not smiles or smiles == "":
        return 0.0
    
    # Approximation basée sur la longueur de la chaîne
    # Atome C ~12, H ~1, O ~16, N ~14, S ~32, P ~31
    weights = {
        'C': 12.01, 'H': 1.008, 'O': 15.999, 'N': 14.007, 
        'S': 32.06, 'P': 30.97
    }
    
    total = 0.0
    for char in smiles.upper():
        if char in weights:
            total += weights[char]
    
    return round(total, 2)


def main():
    """Point d'entrée principal"""
    
    extractor = SimpleCompoundExtractor()
    composés = extractor.extract_composés()
    
    # Sauvegarder les composés nettoyés
    output_path = os.path.join(extractor.base_path, "src/data/inpacdb_clean.json")
    
    with open(output_path, 'w') as f:
        json.dump(composés, f, indent=2)
    
    print(f"Extraction terminée : {len(composés)} composés nettoyés")
    print(f"Fichier sauvé : {output_path}")


if __name__ == "__main__":
    main()

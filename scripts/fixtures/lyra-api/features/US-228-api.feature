# language: fr
@US-228 @REQ-228 @api
Fonctionnalité: Générer à partir de morceaux déposés par le compositeur (US-228)
  # REQ-228 - critères couverts à ce niveau : AC-4, AC-5, AC-6
  # RÉSOLU (code) : la génération à partir de morceaux déposés n'a pas de route REST ; seul le CLI lyra-ml/tools/inspiration_cli.py (sous-commandes transcrire / generer) l'expose : scénarios exécutés par le CLI réel (HTTP non applicable).

  Contexte:
    Soit l'API Lyra joignable

  # Reproduire exactement 8 puis 12 notes d'une source exige de forcer le moteur : non déterministe sans calibrage (voir rapport).
  @AC-4 @api @cli @non-resolu @non-deterministe
  Scénario: Garde-fou plagiat : alerte à 8 notes, refus à 12
    Soit un dossier d'entrée contenant "simple-4-mesures.mid"
    Quand j'exécute la commande "generer" avec les options "--graine 1"
    Alors le code de sortie vaut 0

  @AC-5 @api @cli
  Scénario: Audio non corrigé refusé sans --sans-correction
    Soit un dossier d'entrée contenant "boucle.wav"
    Quand j'exécute la commande "generer" avec les options "--graine 1"
    Alors le code de sortie n'est pas 0

  @AC-5 @api @cli @requiert-audio
  Scénario: Audio non corrigé accepté avec --sans-correction, le rapport l'indique en tête
    Soit un dossier d'entrée contenant "boucle.wav"
    Quand j'exécute la commande "generer" avec les options "--graine 1 --sans-correction"
    Alors le code de sortie vaut 0

  @AC-5 @api @cli
  Scénario: Fichier dont la signature ne correspond à aucun format accepté refusé
    Soit un dossier d'entrée contenant "illisible.bin"
    Quand j'exécute la commande "generer" avec les options "--graine 1"
    Alors le code de sortie n'est pas 0

  @AC-6 @api @cli
  Scénario: Aucune copie du fichier déposé n'est conservée dans le stockage de Lyra
    Soit un dossier d'entrée contenant "simple-4-mesures.mid" et "trio-guitare-basse-batterie.mid"
    Quand j'exécute la commande "generer" avec les options "--graine 1"
    Alors le code de sortie vaut 0
    Et le stockage de Lyra ne contient aucun fichier "simple-4-mesures.mid"

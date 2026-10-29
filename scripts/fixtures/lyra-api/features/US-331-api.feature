# language: fr
@US-331 @REQ-331 @api
Fonctionnalité: Ingérer en lot son corpus personnel (Guitar Pro, BFD3, audio) (US-331)
  # REQ-331 - critères couverts à ce niveau : AC-3, AC-4, AC-6, AC-7
  # RÉSOLU (code) : POST /api/corpus-personnel/ingestions { typeSource, attributionRequise, fichiers:[{nomFichier, contenuBase64}] } -> 202 (job « en_cours ») ; le worker interne traite via RabbitMQ (présent sur la pile). Pas de fixture GP5 valide : les cas « ingéré » utilisent bfd3_midi (MIDI) ; le fichier illisible est un .gp5 invalide.
  # RÉSOLU (code) : pour bfd3_midi l'élément de batterie est déduit du NOM de fichier (kick, snare, hihat…, ElementBatterieResolver) : les fixtures sont nommées en conséquence.
  # OBSERVÉ (hors AC) : l'omission de « attributionRequise » (booléen primitif) est refusée en 400 « pas un JSON valide » alors qu'un constructeur à 2 arguments existe.

  Contexte:
    Soit l'API Lyra joignable

  @AC-3 @AC-4 @api
  Scénario: Lot versé : 202, état agrégé du job et pièce en corpus personnel
    Quand je verse un lot "job" avec les fichiers "unique-kick-4-mesures.mid" sous le type de source "bfd3_midi" et les champs :
      """
      {}
      """
    Alors la réponse a le statut 202
    Quand j'attends au plus 60 secondes que GET "/api/corpus-personnel/jobs/{job}" renvoie "statut" parmi ["termine", "echec", "termine_partiel"]
    Alors le champ "totalSoumis" vaut 1
    Et le champ "totalIngere" vaut 1
    Et la liste "fichiers" contient un élément dont "statut" vaut "ingere"

  @AC-6 @api
  Scénario: Réversement du même fichier : deja_ingere sans nouvelle pièce
    Quand je verse un lot "job1" avec les fichiers "unique-kick-4-mesures.mid" sous le type de source "bfd3_midi" et les champs :
      """
      {}
      """
    Et j'attends au plus 60 secondes que GET "/api/corpus-personnel/jobs/{job1}" renvoie "statut" parmi ["termine", "echec", "termine_partiel"]
    Et je verse un lot "job2" avec les fichiers "unique-kick-4-mesures.mid" sous le type de source "bfd3_midi" et les champs :
      """
      {}
      """
    Et j'attends au plus 60 secondes que GET "/api/corpus-personnel/jobs/{job2}" renvoie "statut" parmi ["termine", "echec", "termine_partiel"]
    Alors la liste "fichiers" contient un élément dont "statut" vaut "deja_ingere"

  # Les fichiers guitar_pro restent « en_attente » (aucun consommateur observé dans la pile) : environnement.
  @AC-7 @api @requiert-worker-gp
  Scénario: Fichier Guitar Pro illisible en échec avec motif
    Quand je verse un lot "job" avec les fichiers "illisible.gp5" sous le type de source "guitar_pro" et les champs :
      """
      {}
      """
    Et j'attends au plus 60 secondes que GET "/api/corpus-personnel/jobs/{job}" renvoie "statut" parmi ["termine", "echec", "termine_partiel"]
    Alors un élément de "fichiers" a "statut" égal à "echec"
    Et un élément de "fichiers" a "motifEchec" non vide

  @AC-7 @api
  Scénario: Un MIDI corrompu est en échec, l'autre fichier du lot est ingéré
    Quand je verse un lot "job" avec les fichiers "snare-illisible.mid,unique-kick-4-mesures.mid" sous le type de source "bfd3_midi" et les champs :
      """
      {}
      """
    Et j'attends au plus 60 secondes que GET "/api/corpus-personnel/jobs/{job}" renvoie "statut" parmi ["termine", "echec", "termine_partiel"]
    Alors la liste "fichiers" contient un élément dont "statut" vaut "echec"
    Et la liste "fichiers" contient un élément dont "statut" vaut "ingere"

  # Un fichier .db illisible pour weimar_jazz_db ne doit pas provoquer d'erreur serveur (500).
  @AC-7 @api
  Scénario: Fichier weimar illisible : jamais d'erreur serveur
    Quand je verse un lot "job" avec les fichiers "weimar-illisible.db" sous le type de source "weimar_jazz_db" et les champs :
      """
      {"attributionRequise": true, "attributionTexte": "Weimar Jazz Database"}
      """
    Alors la réponse a l'un des statuts 202, 400, 422

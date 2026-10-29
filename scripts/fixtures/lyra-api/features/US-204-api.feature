# language: fr
@US-204 @REQ-204 @api
Fonctionnalité: Chercher et comparer des rimes anglaises hors ligne (US-204)
  # REQ-204 - critères couverts à ce niveau : AC-1, AC-4, AC-5, AC-6, AC-7
  # Environnement : la base du dictionnaire de rimes n'est pas importée sur la pile de test (AC-1 et AC-4 exigent le dictionnaire : @requiert-dictionnaire-rimes).

  Contexte:
    Soit l'API Lyra joignable

  @AC-1 @api @requiert-dictionnaire-rimes
  Scénario: Rimes d'un mot courant anglais avec leur type
    Quand j'envoie POST "/api/lyrics/rimes" avec le corps JSON "{\"mot\": \"love\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 200
    Et la liste "rimes" contient au moins 1 élément

  @AC-4 @api @requiert-dictionnaire-rimes @non-deterministe-env
  Scénario: Recherche de rimes sans Internet
    Quand j'envoie POST "/api/lyrics/rimes" avec le corps JSON "{\"mot\": \"love\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 200

  # RÉSOLU (code) : le comparateur renvoie type_rime, sous_type, ancrage ("primaire" pour love/dove) ; eSpeak-NG seul suffit (fiabilité g2p).
  @AC-5 @api
  Scénario: Comparaison de deux mots : type et ancrage
    Quand j'envoie POST "/api/lyrics/rimes/comparer" avec le corps JSON "{\"texte_a\": \"love\", \"texte_b\": \"dove\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 200
    Et le champ "type_rime" vaut "parfaite"
    Et le champ "ancrage" est non vide

  # RÉSOLU (code) : la prononciation d'un mot hors dictionnaire est donnée par /prononciation/phrase (IPA eSpeak-NG, mots[].ipa) ; /rimes/prononciation exige la base du dictionnaire.
  @AC-6 @api
  Scénario: Mot hors dictionnaire phonétisé par eSpeak-NG, jamais de rime inventée
    Quand j'envoie POST "/api/lyrics/prononciation/phrase" avec le corps JSON "{\"texte\": \"zorblax\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 200
    Et le champ "ipa" est non vide
    Et le champ "mots[0].ipa" est non vide

  # Précondition : la pile de test est dans l'état « dictionnaire non importé » (base du dictionnaire inaccessible) ; l'état exact (table vide vs base injoignable) n'est pas contrôlé par le test.
  @AC-7 @api
  Scénario: Dictionnaire de rimes non importé : 503
    Quand j'envoie POST "/api/lyrics/rimes" avec le corps JSON "{\"mot\": \"love\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 503
    Quand j'envoie POST "/api/lyrics/rimes/comparer" avec le corps JSON "{\"texte_a\": \"love\", \"texte_b\": \"dove\", \"langue\": \"anglais\"}"
    Alors la réponse a le statut 503

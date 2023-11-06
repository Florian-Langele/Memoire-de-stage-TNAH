var example_1 = {
  "distinct": true,
  "variables": [
    "Archives",
    "Sceau",
    "Auteur",
    "Lieu"
  ],
  "order": null,
  "branches": [
    {
      "line": {
        "s": "?Archives",
        "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourAuteur",
        "o": "?Auteur",
        "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Archives",
        "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Personne",
        "values": []
      },
      "children": [
        {
          "line": {
            "s": "?Auteur",
            "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourActivite",
            "o": "?Activite_4",
            "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Personne",
            "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Activite",
            "values": [
              {
                "label": "prévôt de Paris",
                "rdfTerm": {
                  "type": "uri",
                  "value": "http://data.oresm.fr/occupationType/pr%C3%A9v%C3%B4t%20de%20Paris"
                }
              }
            ]
          },
          "children": []
        }
      ]
    },
    {
      "line": {
        "s": "?Archives",
        "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#noteSceau",
        "o": "?Sceau",
        "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Archives",
        "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Sceau",
        "values": []
      },
      "children": []
    },
    {
      "line": {
        "s": "?Archives",
        "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourLieuPassage",
        "o": "?Lieu",
        "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Archives",
        "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Lieu",
        "values": []
      },
      "children": []
    }
  ]
}


var example_2 = {
  "distinct": true,
  "variables": [
    "Personne_1",
    "Activite_8",
    "Archives_2"
  ],
  "order": null,
  "branches": [
    {
      "line": {
        "s": "?Personne_1",
        "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#estAuteurDe",
        "o": "?Archives_2",
        "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Personne",
        "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Archives",
        "values": []
      },
      "children": [
        {
          "line": {
            "s": "?Archives_2",
            "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourLangue",
            "o": "?Langue_4",
            "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Archives",
            "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Langue",
            "values": [
              {
                "label": "français (955)",
                "rdfTerm": {
                  "type": "uri",
                  "value": "http://data.archives-nationales.culture.gouv.fr/language/FRAN_RI_100-name4"
                }
              }
            ]
          },
          "children": []
        },
        {
          "line": {
            "s": "?Archives_2",
            "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourTypeDeDocument",
            "o": "?DocumentaryFormType_6",
            "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Archives",
            "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#DocumentaryFormType",
            "values": [
              {
                "label": "acte notarié (240)",
                "rdfTerm": {
                  "type": "uri",
                  "value": "http://data.oresm.fr/type/acte%20notari%C3%A9"
                }
              }
            ]
          },
          "children": []
        }
      ]
    },
    {
      "line": {
        "s": "?Personne_1",
        "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourActivite",
        "o": "?Activite_8",
        "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Personne",
        "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Activite",
        "values": []
      },
      "children": []
    }
  ]
}

var example_3 = {
  "distinct": true,
  "variables": [
    "Archives_1",
    "Identifiant_10",
    "Nom_4",
    "Personne_8"
  ],
  "order": null,
  "branches": [
    {
      "line": {
        "s": "?Archives_1",
        "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourDateDeCréation",
        "o": "?Date_2",
        "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Archives",
        "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Date",
        "values": []
      },
      "children": [
        {
          "line": {
            "s": "?Date_2",
            "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourFormeNormalisée",
            "o": "?Nom_4",
            "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Date",
            "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Nom",
            "values": [
              {
                "label": "de 01/01/1200 à 01/01/1300",
                "start": "1199-12-31T23:50:39.000Z",
                "stop": "1300-01-01T23:50:38.059Z"
              }
            ]
          },
          "children": []
        }
      ]
    },
    {
      "line": {
        "s": "?Archives_1",
        "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourAuteur",
        "o": "?Personne_8",
        "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Archives",
        "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Personne",
        "values": []
      },
      "children": []
    },
    {
      "line": {
        "s": "?Archives_1",
        "p": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#aPourCoteActuelle",
        "o": "?Identifiant_10",
        "sType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Archives",
        "oType": "https://sparna-git.github.io/sparnatural-demonstrateur-an/ontology#Identifiant",
        "values": []
      },
      "children": []
    }
  ]
}
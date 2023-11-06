<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:cc="http://creativecommons.org/ns#" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:ric-dft="https://www.ica.org/standards/RiC/vocabularies/documentaryFormTypes#"
    xmlns:ric-rst="https://www.ica.org/standards/RiC/vocabularies/recordSetTypes#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
    xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:oresm-onto="http://data.oresm.fr/ontology#"
    exclude-result-prefixes="xs xd cc skos ric-dft ric-rst xsd dcterms" version="2.0">
    
    
    
    <xd:doc scope="stylesheet">
        <xd:desc>o
            <xd:p><xd:b>Created on:</xd:b> Nov 20, 2021</xd:p>
            <xd:p><xd:b>Author:</xd:b> Florence Clavaud</xd:p>
            <xd:p>Complété par Florian Langelé en 2023</xd:p>
            <xd:p>Projet ORESM : conversion en RDF des tableaux de dépouillement des archives
                du collège des Cholets. Prend en entrée le fichier
                src/depouillement-actes-cholets-en-XML_v20112021.xml</xd:p>
            <xd:p>Modifié en 2023, pour : prendre en compte l'ensemble des fichiers de dépouillement produits jusqu'ici et les nouvelles règles de saisie de ces fichiers ; traiter les dates comme des entités</xd:p>
            <xd:p>Cette XSLT génère en une seule passe, à partir de l'ensemble des fichiers XML déposés dans le dossier 'src-xml/depouillements, l'ensemble des données RDF, sérialisées en RDF/XML et enregistrées sous la forme d'une série de fichiers dans le dossier output-rdf.</xd:p>
            
            <xd:p>Le point de départ est un fichier XML vide (fichier vide.xml). Ca marche très bien dans oXygen ainsi. On pourrait faire autrement, notamment en utilisant directement un processeur XSLT comme Saxon.</xd:p>
            <xd:p>L'idée générale est de s'occuper pour commencer des entités contextuelles (personnes, lieux, dates, cotes, etc.) puis des documents. On sort le plus souvent les relations entre entités contextuelles et documents dans la decsription des entités contextuelles. L'ontologie ORESM-ONTO spécifie les relations inverses, qui peuvenbt donc être inférées par n'importe quel raisonneur RDFS/OWL</xd:p>
            <xd:p>LA XSLT est loin d'être terminée, il y reste beaucoup à faire. PAr ailleurs elle ne procède à aucun regroupement sauf lorsque les noms des entités sont structement identiques. Les processus d'alignement sont à faire soit en amont soit en aval à partir du RDF.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <!-- Pour executer cette XSLT il faut configurer le schéma de transformation pour se lancer à partir d'un fichier XML vide tout en configurant la bonne arborescence dans les variables qui suivent-->
    
    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="guillemet">"</xsl:variable>
    <!-- on va avoir besoin de certains référentiels des AN, ils sont dans le dossier src-rdf et doivent bien sûr être importés dans la base GraphDB (les isoler dans un graphe nommé spécifique) -->
    <xsl:variable name="typesDocAN"
        select="document('../src-rdf/FRAN_RI_001_documentaryFormTypes.rdf')/rdf:RDF"/>
    <xsl:variable name="etatsAN" select="document('../src-rdf/FRAN_RI_001_recordStates.rdf')/rdf:RDF"/>
    <xsl:variable name="supportsAN"
        select="document('../src-rdf/FRAN_RI_002_carrierTypes.rdf')/rdf:RDF"/>
    <xsl:variable name="languesAN" select="document('../src-rdf/FRAN_RI_100_languages.rdf')/rdf:RDF"/>
   <!-- une variable pour accéder au contenu de l'ensemble des fichiers à traiter -->
    <xsl:variable name="dossierDept">
        <xsl:value-of select="concat('../src-xml/depouillements/', '?select=*.xml;recurse=yes;on-error=warning')"/>
    </xsl:variable>
   
    <xsl:variable name="fichiersDept" select="collection($dossierDept)"/>
    <!-- on part donc du fichier vide.xml -->
   <xsl:template match="/">
       <!-- ### les personnes pour commencer ### -->
       <!-- la méthode de génération du RDF relatif aux entités de contexte est globalement tojours la même : on produit des variables qui listent ces entités, puis on opère des regroupements ; on génère le RDF à partir de la dernière variable produite. -->
        <xsl:variable name="personnes">
            <personnes>
                <xsl:for-each select="$fichiersDept/documents/document/Personne_physique">
                    <xsl:variable name="idEAD" select="normalize-space(replace(parent::document/Identifiant_du_guide, '—', '--'))"/>
                
                    <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                  
                    <xsl:variable name="notice"
                        select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                    <xsl:variable name="date" select="
                        if (normalize-space(parent::document/Date__forme_normalisée_)!='')
                        
                        then normalize-space(parent::document/Date__forme_normalisée_)
                        
                        else (
                        
                        if (normalize-space(parent::document/Date__forme_rédigée_)!='')
                        
                        then (
                        normalize-space(parent::document/Date__forme_rédigée_))
                        
                        else ('sans date')
                        )
                        
                        "/>

                    <xsl:for-each select="tokenize(., '\|')[. != '']">
                        <xsl:variable name="nom" select="normalize-space(replace(substring-after(., ']'),'&#xa0;' , ' '))"/>
                        <xsl:if test="normalize-space($nom)!=''">
                        <personne>
                            <role>
                                <xsl:value-of
                                    select="substring-after(substring-before(., ']'), '[')"/>
                            </role>
                            <nom>
                                <xsl:value-of select="$nom"/>
                            </nom>
                            <idEAD>
                                <xsl:value-of select="$idEAD"/>
                            </idEAD>
                            
                            <cote>
                                <xsl:value-of select="$cote"/>
                            </cote>
                            <notice>
                                <xsl:value-of select="$notice"/>
                            </notice>
                            <date><xsl:value-of select="$date"/></date>
                        </personne>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:for-each>
            </personnes>
        </xsl:variable>
       <!-- l'instruction ci-dessous sert à sérialiser, dans le dossier xml-temp, le contenu de la variable, histoire de mieux voir ce qu'on a. On peut sans problème se passer de cette instruction et de toutes celles de même nature qui suivent. C'est juste très pratique pour travailler -->
        <xsl:result-document href="../xml-temp/liste-personnes-all.xml" method="xml" encoding="utf-8"
            indent="yes">
            <xsl:copy-of select="$personnes"/>
        </xsl:result-document>
        <xsl:variable name="merged-persons">
            <personnes>
                <xsl:for-each-group select="$personnes/personnes/personne" group-by="nom">
                    <xsl:sort select="current-grouping-key()"/>
                    <personne>
                        <nom>
                            <xsl:value-of select="current-grouping-key()"/>
                        </nom>
                        <xsl:for-each select="current-group()">
                            <infos>
                                <xsl:value-of select="idEAD"/>
                                <xsl:text> [cote </xsl:text>
                                <xsl:value-of select="cote"/>
                                <xsl:text>] (notice </xsl:text>
                                <xsl:value-of select="notice"/>
                                <xsl:text>) \\ date </xsl:text>
                                
                                <xsl:value-of select="date"/>
                                <xsl:if test="normalize-space(role)!='' and normalize-space(role)!='[]'">
                                <xsl:text>// : </xsl:text>
                                <xsl:value-of select="role"/>
                                </xsl:if>
                            </infos>
                        </xsl:for-each>
                    </personne>
                </xsl:for-each-group>
            </personnes>
        </xsl:variable>
        <xsl:result-document href="../xml-temp/liste-personnes-dedoublonnees-all.xml" method="xml"
            encoding="utf-8" indent="yes">
            <xsl:copy-of select="$merged-persons"/>
        </xsl:result-document>
       <!-- on a besoin de sortir une liste des roles - qui vont servir à instancier les relations entre les personnes et les documents -->
        <xsl:variable name="roles">
            <roles>
                
                <xsl:for-each-group select="$merged-persons/personnes/personne/infos" group-by="
                    
                    if (contains(normalize-space(substring-after(., ':')), '- ajouté FC'))
                    then (normalize-space(substring-before(normalize-space(substring-after(., ':')), '- ajouté FC')))
                    
                    else (normalize-space(normalize-space(substring-after(., ':'))))
                    
                    
                    ">
                    <xsl:sort select="current-grouping-key()"/>
                
                    <role><xsl:value-of select="current-grouping-key()"/></role>
                    
                    
                </xsl:for-each-group>
            </roles>
        </xsl:variable>
        <xsl:result-document href="../xml-temp/liste-roles-all.xml" method="xml"
            encoding="utf-8" indent="yes">
            <xsl:copy-of select="$roles"/>
        </xsl:result-document>
        <!-- On a aussi besoin d'instancier les activités -->
        <xsl:variable name="occupations">
            <occupations>
                
                <xsl:for-each-group select="$merged-persons/personnes/personne/nom" group-by="
                 
                    
                    normalize-space(tokenize(normalize-space(substring-before(substring-after(., '('), ')')), ';')[1])
                    
                    ">
                    <xsl:sort select="current-grouping-key()"></xsl:sort>
                    <xsl:if test="current-grouping-key()!='[]' and current-grouping-key()!=''">
                        <occupation>
                            <xsl:value-of select="current-grouping-key()"/>
                        
                            </occupation>
                    </xsl:if>
                    
                </xsl:for-each-group>
            </occupations>



        </xsl:variable>
        <xsl:result-document href="../xml-temp/liste-occupations-all.xml" method="xml"
            encoding="utf-8" indent="yes">
            <xsl:copy-of select="$occupations"/>
        </xsl:result-document>
        <!-- retraitement des activités -->
        <xsl:variable name="occupations-processed">
            <xsl:variable name="splitted">
                <splitted>
                <xsl:for-each select="$occupations/occupations/occupation">
                    <xsl:variable name="normName" select="replace(., $apos, '’')"/>
                   <xsl:for-each select="tokenize($normName, '#')[.!='']">
                       <occupation><xsl:value-of select="normalize-space(.)"/></occupation>
                   </xsl:for-each>
                    
                </xsl:for-each>
                </splitted>
            </xsl:variable>
            <occupations-def>
          
                <xsl:for-each-group select="$splitted/splitted/occupation" group-by=".">
                    <xsl:sort select="current-grouping-key()" lang="fr"></xsl:sort>
                    <occupation><xsl:value-of select="current-grouping-key()"/></occupation>
                </xsl:for-each-group>
            </occupations-def>
        </xsl:variable>
        <xsl:result-document href="../xml-temp/liste-occupations-def-all.xml" method="xml"
            encoding="utf-8" indent="yes">
            <xsl:copy-of select="$occupations-processed"/>
        </xsl:result-document>
       <!-- le premier fichier RDF concerne les activités, instances de RiC-O OccupationType-->
        <xsl:result-document href="../output-rdf/occupations-all.rdf" method="xml" encoding="utf-8" indent="yes">
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
                xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
                <!-- Ici on exclut tout ce qui n'est pas une profession ou un état permanent, donc les liens de parenté ou infos connexes ; j'en ai peut-être oublié, DONE FLORIAN A VERIFIER -->
                <!-- nota on pourra tenter un alignement avec le référentiel des activités des AN -->
                <xsl:for-each select="$occupations-processed/occupations-def/occupation[not(starts-with(., 'veuve '))  and not(starts-with(.,'mère ')) and not(starts-with(.,'père ')) and not(starts-with(.,'femme ')) and not(starts-with(., 'auparavant femme de ')) and not(starts-with(., 'fils ')) and not(starts-with(., 'fille ')) and not(starts-with(., 'frère ')) and not(starts-with(., 'sœur ')) and not(starts-with(., 'cousin ')) and not(starts-with(., 'fiancée de '))
                    and     not(starts-with(.,'héritier ')) and not(starts-with(.,'héritière ')) and (starts-with(.,'enfant de chœur') or not(starts-with(.,'enfant ')))
                    and not(starts-with(.,'tuteur')) and (starts-with(.,'procureur de l’abbaye') or not(starts-with(.,'procureur de')))  and not(starts-with(.,'procureur d’'))
                    ]">
                    <xsl:variable name="myName" select="."/>
                    <rico:OccupationType>
                        <xsl:attribute name="rdf:about">
                            <xsl:value-of select="concat('occupationType/', encode-for-uri($myName))"/>
                            
                        </xsl:attribute>
                        <rdfs:label xml:lang="fr"><xsl:value-of select="$myName"/></rdfs:label>
                        <rico:name xml:lang="fr"><xsl:value-of select="$myName"/></rico:name>
                    </rico:OccupationType>
                </xsl:for-each>
                
                
            </rdf:RDF>
            
        </xsl:result-document>
       <!-- maintenant on produit le fichier RDF des personnes physiques -->
        <xsl:result-document href="../output-rdf/personnes-all.rdf" method="xml" encoding="utf-8" indent="yes">
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
                xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">

                <xsl:for-each
                    select="$merged-persons/personnes/personne[not(starts-with(nom, '«'))]">
                    <xsl:sort select="nom" lang="fr"/>
                    <!-- <Personnes_physiques>[auteur] JEHAN de Harlus (garde des sceaux aux obligations de la châtellenie et prévôté de Béthisy et Verberie ; []) [[] ; [] ; [] ; []] | [rédacteur] JEHAN de la Rue (clerc juré commis au tabellionnage de la prévôté de Béthisy et Verberie ; []) [[] ; [] ; [] ; []] | [auteur] GUILLAUME Le Sueur (laboureur ; []) [[] ; [] ; [] ; []] | [témoin] GUILLAUME Vinart (prévôt de Béthisy et Verberie ; []) [[] ; [] ; [] ; []]</Personnes_physiques>-->
                    <!--  <Personnes_physiques>[auteur] Martin IV (pape ; 1220-1281) [0000 0000 5315 0353 ; 086043064 ; [] ; Q227719] | [destinataire] JEAN Cholet (cardinal ; 12..-1293) [0000000017204924 ; 167364952 ; [] ; Q1772058]</Personnes_physiques>-->
                    
                   <xsl:variable name="persName" select="child::nom"/>
                    
                        
                    <xsl:variable name="myName">
                        <xsl:value-of select="if (contains($persName, '('))
                            then normalize-space(substring-before($persName, '('))
                            
                            else normalize-space($persName)"/>
                    </xsl:variable>
                    <!-- Normalise le texte en ajoutant une majuscule à chaque première lettre d'un nom puis des minuscules -->
                        <xsl:variable name="mySddName">
                            <xsl:for-each select="tokenize($myName, ' ')[normalize-space(.)!='']">
                                <xsl:value-of select="upper-case(substring(normalize-space(.), 1,1))"/>
                                <xsl:value-of select="lower-case(replace(substring(normalize-space(.), 2), $apos, '’'))"/>
                                <xsl:if test="position()!=last()"><xsl:text> </xsl:text></xsl:if>
                            </xsl:for-each>
                        </xsl:variable>
                    <!-- Récupère les valeurs entre parenthèse si c'est une occupation-->
                    <xsl:variable name="par">
                        <xsl:value-of select="normalize-space(substring-before(substring-after($persName, '('), ')'))"/>
                    </xsl:variable>
                    <xsl:variable name="firstParStr">
                        <xsl:value-of select="normalize-space(tokenize($par, ';')[1])"/>
                    </xsl:variable>
                    <xsl:variable name="normFirstParStr" select="replace($firstParStr, $apos, '’')"/>
                    <xsl:variable name="processedFirstParStr">
                        <xsl:choose>
                            <xsl:when test="$normFirstParStr='[]'">
                                <xsl:value-of select="$normFirstParStr"/>
                            </xsl:when>
                            <xsl:otherwise>
                               
                                <xsl:for-each select="tokenize($normFirstParStr, '#')[.!='']">
                                    <xsl:if test="not(starts-with(., 'veuve '))  and not(starts-with(.,'mère ')) and not(starts-with(.,'père ')) and not(starts-with(.,'femme ')) and not(starts-with(., 'auparavant femme de ')) and not(starts-with(., 'fils ')) and not(starts-with(., 'fille ')) and not(starts-with(., 'frère ')) and not(starts-with(., 'sœur ')) and not(starts-with(., 'cousin ')) and not(starts-with(., 'fiancée de '))
                                        and     not(starts-with(.,'héritier ')) and not(starts-with(.,'héritière ')) and (starts-with(.,'enfant de chœur') or not(starts-with(.,'enfant ')))
                                        and not(starts-with(.,'tuteur')) and (starts-with(.,'procureur de l’abbaye') or not(starts-with(.,'procureur de '))) and not(starts-with(.,'procureur d’'))"
                                        >
                                      
                                        <xsl:value-of select="normalize-space(.)"/>
                                        <xsl:if test="position()!=last()">
                                            <xsl:text>, </xsl:text>
                                        </xsl:if>
                                    </xsl:if>
                                </xsl:for-each>
                                
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="lastParStr">
                        <xsl:value-of select="normalize-space(tokenize($par, ';')[2])"/>
                    </xsl:variable>
                    <xsl:variable name="authorizedName">
                        <xsl:value-of select="$mySddName"/>
                        <!-- on isole la partie entre parenthèses -->
                        <!-- ROBERTUS de Vallencourt (notaire public par l’autorité apostolique ; []) [[] ; [] ; [] ; []]-->
                      
                        <xsl:choose>
                            <xsl:when test="($processedFirstParStr!='[]' and $processedFirstParStr!='') or ($lastParStr!='[]' and $lastParStr!='')">
                                <xsl:text> (</xsl:text>
                               <!-- <xsl:value-of select="concat(' (', normalize-space(replace($firstParStr, ' #', ',')))"/>-->
                                <xsl:if test="$processedFirstParStr!='[]' and $processedFirstParStr!=''">
                                <xsl:value-of select="$processedFirstParStr"/>
                                    <xsl:if test="$lastParStr!='[]' and $lastParStr!=''">
                                        <xsl:text> ; </xsl:text>
                                    </xsl:if>
                                </xsl:if>
                                <xsl:if test="$lastParStr!='[]' and $lastParStr!=''">
                                    <xsl:value-of select="replace($lastParStr,' ','')"/>
                                </xsl:if>
                              <xsl:text>)</xsl:text>
                            </xsl:when>
                            <xsl:when test="$processedFirstParStr='[]' or $processedFirstParStr=''">
                                <xsl:if test="$lastParStr='[]' or $lastParStr=''"></xsl:if>
                                <xsl:if test="$lastParStr!='[]' and  $lastParStr!=''">
                                    <xsl:value-of select="concat(' (', replace($lastParStr,' ',''), ')')"/>
                                </xsl:if>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                   
                    <rico:Person>
                        <xsl:attribute name="rdf:about">
                            <xsl:value-of select="concat('person/', encode-for-uri($authorizedName))"/>
                        </xsl:attribute>
                        <rdfs:label xml:lang="fr">
                            <xsl:value-of select="$authorizedName"/>
                        </rdfs:label>
                        <rico:name xml:lang="fr">
                            <xsl:value-of select="$authorizedName"/>
                        </rico:name>
                       
                        <xsl:for-each select="tokenize($normFirstParStr, '#')[.!='' and .!='[]']">
                            <xsl:variable name="occupationNormalise" select="normalize-space(.)"/>
                            <xsl:if test="not(starts-with($occupationNormalise, 'veuve '))  and not(starts-with($occupationNormalise,'mère ')) and not(starts-with($occupationNormalise,'père ')) and not(starts-with($occupationNormalise,'femme ')) and not(starts-with($occupationNormalise, 'auparavant femme de ')) and not(starts-with($occupationNormalise, 'fils ')) and not(starts-with($occupationNormalise, 'fille ')) and not(starts-with($occupationNormalise, 'frère ')) and not(starts-with($occupationNormalise, 'sœur ')) and not(starts-with($occupationNormalise, 'cousin ')) and not(starts-with($occupationNormalise, 'fiancée de '))
                                and     not(starts-with($occupationNormalise,'héritier ')) and not(starts-with($occupationNormalise,'héritière ')) and (starts-with($occupationNormalise,'enfant de chœur') or not(starts-with($occupationNormalise,'enfant ')))
                                and not(starts-with($occupationNormalise,'tuteur')) and (starts-with($occupationNormalise,'procureur de l’abbaye') or not(starts-with($occupationNormalise,'procureur de '))) and not(starts-with($occupationNormalise,'procureur d’'))
                                ">
                                
                              <rico:hasOrHadOccupationOfType>
                                  <xsl:attribute name="rdf:resource">
                                      <xsl:value-of select="concat('occupationType/', encode-for-uri(normalize-space(.)))"/>
                                  </xsl:attribute>
                              </rico:hasOrHadOccupationOfType>
                            </xsl:if>
                        </xsl:for-each>
                        
                        <!-- on génère des éléments bio au moins pour les indications entre parenthèses qui n'ont pas servi pour les activités -->
                        
                        <xsl:if test="tokenize($normFirstParStr, '#')[starts-with(., 'veuve ')  or starts-with(.,'mère ') or starts-with(.,'père ') or starts-with(.,'femme ') or starts-with(., 'auparavant femme de ') or starts-with(., 'fils ') or starts-with(., 'fille ') or starts-with(., 'frère ') or starts-with(., 'sœur ') or starts-with(., 'cousin ') or starts-with(., 'fiancée de ')
                            or    starts-with(.,'héritier ') or starts-with(.,'héritière ') or (starts-with(.,'enfant') and not(starts-with(.,'enfant de chœur')))
                            or starts-with(.,'tuteur') or (starts-with(.,'procureur de ') and not(starts-with(.,'procureur de l’abbaye')))  or starts-with(.,'procureur d’')]"
                                >
                            <!-- -->
                            <xsl:variable name="sources">
                                <xsl:for-each select="infos">
                                    <xsl:variable name="cote">
                                        <xsl:value-of select="substring-before(substring-after(., ' [cote'), ']')"/>
                                    </xsl:variable>
                                    <xsl:variable name="ORESMDocId">
                                        <xsl:value-of select="concat('or-', substring-before(substring-after(., 'notice '), ')'))"/>
                                    </xsl:variable>
                                    <xsl:value-of select="concat($cote, ' (ORESM id : ', $ORESMDocId, ')')"/>
                                    <xsl:if test="position()!=last()"><xsl:text> ; </xsl:text></xsl:if>
                                </xsl:for-each>
                            </xsl:variable>
                         
                            <rico:descriptiveNote rdf:parseType="Literal">
                                <html:div xml:lang="fr">
                                    <html:p>
                                        
                                        <xsl:for-each select="tokenize($normFirstParStr, '#')[starts-with(., 'veuve ')  or starts-with(.,'mère ') or starts-with(.,'père ') or starts-with(.,'femme ') or starts-with(., 'auparavant femme de ') or starts-with(., 'fils ') or starts-with(., 'fille ') or starts-with(., 'frère ') or starts-with(., 'sœur ') or starts-with(., 'cousin ') or starts-with(., 'fiancée de ')
                                            or    starts-with(.,'héritier ') or starts-with(.,'héritière ') or (starts-with(.,'enfant') and not(starts-with(.,'enfant de chœur')))
                                            or starts-with(.,'tuteur') or starts-with(.,'procureur de ') or starts-with(.,'procureur d’')]"
                                            >
                                            <xsl:value-of select="."/>
                                         
                                           
                                            <xsl:if test="position()!=last()"><xsl:text> ; </xsl:text></xsl:if>
                                        </xsl:for-each>
                                        <xsl:text> [Sources : </xsl:text>
                                        <xsl:value-of select="$sources"/>
                                       <xsl:text>]</xsl:text>                                   </html:p>
                                </html:div>
                            </rico:descriptiveNote>
                                
                            
                        </xsl:if>
                        <xsl:variable name="refsString"
                            select="normalize-space(substring-after($persName, ')'))"/>
                        <!-- <xsl:for-each select="tokenize($refsString, ' ;')[normalize-space(.)!='' and normalize-space(.)!='[]' and normalize-space(.)!='[[]']">-->
                        <xsl:for-each select="tokenize($refsString, ';')">
                            <!-- isni, idref, an, wikidata-->
                            <xsl:choose>
                                <xsl:when test="position() = 1 and normalize-space(.) != '[[]'">
                                    <!-- isni-->
                                    <!--<isni:identifierValid><xsl:value-of select="normalize-space(.)"/></isni:identifierValid>-->
                                    <owl:sameAs>
                                        <xsl:attribute name="rdf:resource">
                                            <xsl:value-of
                                                select="concat('http://isni.org/isni/', normalize-space(replace(substring-after(., '['), ' ', '')))"
                                            />
                                        </xsl:attribute>
                                    </owl:sameAs>
                                </xsl:when>
                                <xsl:when test="position() = 2 and normalize-space(.) != '[]'">
                                    <!-- idref-->
                                    <!-- http://www.idref.fr/086043064/id-->
                                    <owl:sameAs>
                                        <xsl:attribute name="rdf:resource">
                                            <xsl:value-of
                                                select="concat('http://www.idref.fr/', normalize-space(.), '/id')"
                                            />
                                        </xsl:attribute>
                                    </owl:sameAs>
                                </xsl:when>
                                <xsl:when test="position() = 3 and normalize-space(.) != '[]'">
                                    <!-- an-->
                                    <!-- [[] ; 253188458 ; FRAN_NP_012635 ; []]-->
                                    <xsl:if test="starts-with(normalize-space(.), 'FRAN_NP')">
                                        <owl:sameAs>
                                            <xsl:attribute name="rdf:resource">
                                                <xsl:value-of
                                                  select="concat('http://data.archives-nationales.culture.gouv.fr/agent/', normalize-space(substring-after(., 'FRAN_NP_')))"
                                                />
                                            </xsl:attribute>
                                        </owl:sameAs>
                                    </xsl:if>
                                    <xsl:if test="starts-with(normalize-space(.), 'Q')">
                                        <owl:sameAs>
                                            <xsl:attribute name="rdf:resource">
                                                <xsl:value-of
                                                  select="concat('http://www.wikidata.org/entity/', normalize-space(substring-before(., ']')))"
                                                />
                                            </xsl:attribute>
                                        </owl:sameAs>
                                    </xsl:if>
                                </xsl:when>
                                <xsl:when test="position() = 4 and normalize-space(.) != '[]]'">
                                    <!-- wikidata-->
                                    <!-- https://www.wikidata.org/entity/Q352  http://www.wikidata.org/entity/Q352-->
                                    <xsl:if test="starts-with(normalize-space(.), 'FRAN_NP')">
                                        <owl:sameAs>
                                            <xsl:attribute name="rdf:resource">
                                                <xsl:value-of
                                                  select="concat('http://data.archives-nationales.culture.gouv.fr/agent/', normalize-space(substring-after(., 'FRAN_NP_')))"
                                                />
                                            </xsl:attribute>
                                        </owl:sameAs>
                                    </xsl:if>
                                    <xsl:if test="starts-with(normalize-space(.), 'Q')">
                                        <owl:sameAs>
                                            <xsl:attribute name="rdf:resource">
                                                <xsl:value-of
                                                  select="concat('http://www.wikidata.org/entity/', normalize-space(substring-before(., ']')))"
                                                />
                                            </xsl:attribute>
                                        </owl:sameAs>
                                    </xsl:if>
                                </xsl:when>
                            </xsl:choose>
                            <!--</xsl:for-each>-->
                            
                          
                            
                        </xsl:for-each>
                        <!-- relation avec doct-->
                        <xsl:for-each select="infos">
                           <!-- <xsl:variable name="ANdocId">
                                <xsl:value-of select="replace(substring-before(., ' [cote'), '—', '-\-')"/>
                            </xsl:variable>-->
                            <xsl:variable name="ORESMDocId">
                                <xsl:value-of select="concat('or-', substring-before(substring-after(., 'notice '), ')'))"/>
                            </xsl:variable>
                            <xsl:variable name="roleStr" select="normalize-space(substring-after(., ':'))"/>
                            
                            <xsl:variable name="trueRoleStr">
                                <xsl:choose>
                                    <xsl:when test="ends-with($roleStr, '- ajouté FC')">
                                        <xsl:value-of select="normalize-space(substring-before($roleStr, '- ajouté FC'))"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$roleStr"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <!--  
   <role>auteur</role> x
   <role>auteur / donateur</role> x
   <role>auteur / rédacteur</role> x
   <role>auteur / testateur</role> x
   <role>bénéficiaire</role> x
   <role>destinataire</role> x
   <role>donataire</role> x
   <role>donateur / auteur</role> x
   <role>personne concernée</role> x
   <role>rédacteur</role> x
   <role>testateur</role> x
   <role>témoin</role> x-->
                            <xsl:for-each select="tokenize($trueRoleStr, '/')">
                                <xsl:choose>
                                    <xsl:when test="normalize-space(.)='personne concernée'">
                                        <rico:isOrWasSubjectOf rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='auteur'">
                                        <rico:isAuthorOf rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='rédacteur'">
                                        <oresm-onto:estRedacteurDe rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='destinataire'">
                                        <rico:isAddresseeOf rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='bénéficiaire'">
                                        <oresm-onto:estBeneficiaireActeConsigneDans rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='donateur'">
                                        <oresm-onto:estDonateurActeConsigneDans rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='testateur'">
                                        <oresm-onto:estTestateurDe rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='donataire'">
                                        <oresm-onto:estDonataireActeConsigneDans rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='témoin'">
                                        <oresm-onto:estTemoinDe rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:for-each>
                            
                        </xsl:for-each>
                    </rico:Person>
                </xsl:for-each>
              
            </rdf:RDF>
        </xsl:result-document>
   
   
      
<!-- ### LES COLLECTIVITES -->
        <!-- [auteur] Officialité de Paris (tribunal ; 11..-17..) [[] ; 185265235 ; [] ; Q99775030]-->
        <!-- <Personnes_morales>[auteur] Collège des Cholets (collectivité ; 1292-1763) [[] ; 067074472 ; [] ; Q2983809]</Personnes_morales>-->
    <!-- <Personne_morale>[auteur] Chapitre de l'Église de Paris | [destinataire] Parlement de Paris</Personne_morale>-->
    <!-- Méthodologie durant le test : 
[role] CorporateBodyName (CorporateBody_type ; YYYY-YYYY) [n°ISNI ; n°IdRef ; n°referentiel_AN ; n°wikidata]
A remplir en renseignant dans cet ordre et en suivant scrupuleusement les signes servant de séparateurs :
1.	le type de personne morale par rapport au document décrit en s’appuyant sur le référentiel « role » (exemple : [auteur])
2.	le nom de la personne morale avec entre parenthèses l’activitéprincipale de la personne morale au moment où le document a été rédigé (exemple : Officialité de Paris (tribunal ; 11..-17..))
3.	les numéros identifiants la personne dans les grands référentiels, entre crochet et toujours dans cet ordre et de la manière suivante [n°ISNI ; n°IdRef ; n°referentiel_AN ; n°wikidata] (exemple : [[] ; 185265235 ; [] ; Q99775030]).-->
        <xsl:variable name="orgs">
            <organismes>
                <xsl:for-each select="$fichiersDept/documents/document/Personne_morale">
                    
                    <xsl:variable name="notice"
                        select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                    <xsl:variable name="date" select="
                        if (normalize-space(parent::document/Date__forme_normalisée_)!='')
                        
                        then normalize-space(parent::document/Date__forme_normalisée_)
                        
                        else (
                        
                        if (normalize-space(parent::document/Date__forme_rédigée_)!='')
                        
                        then (
                        normalize-space(parent::document/Date__forme_rédigée_))
                        
                        else ('sans date')
                        )
                        
                        "/>
                    <xsl:variable name="idEAD" select="normalize-space(replace(parent::document/Identifiant_du_guide, '—', '--'))"/>
                <!--    <xsl:variable name="doc" select="normalize-space(parent::document/Identifiant_du_guide)"/>-->
                    <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                    
                   
                    <xsl:for-each select="tokenize(., '\|')[. != '']">
                        <xsl:variable name="nom" select="normalize-space(replace(substring-after(., ']'),'&#xa0;' , ' '))"/>
                        <xsl:if test="normalize-space($nom)!=''">
                        <organisme>
                            <role>
                                <xsl:value-of
                                    select="substring-after(substring-before(., ']'), '[')"/>
                            </role>
                            <nom>
                                <!--<xsl:value-of select="normalize-space(substring-after(., ']'))"/>-->
                                <xsl:value-of select="$nom"/>
                            </nom>
                            <idEAD>
                                <xsl:value-of select="$idEAD"/>
                            </idEAD>
                            <cote>
                                <xsl:value-of select="$cote"/>
                            </cote>
                            <notice>
                                <xsl:value-of select="$notice"/>
                            </notice>
                            <date><xsl:value-of select="$date"/></date>
                        </organisme>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:for-each>
            </organismes>
        </xsl:variable>
        <xsl:result-document href="../xml-temp/liste-orgs-all.xml" method="xml" encoding="utf-8"
            indent="yes">
            <xsl:copy-of select="$orgs"/>
        </xsl:result-document>
        <xsl:variable name="merged-orgs">
            <organismes>
                <xsl:for-each-group select="$orgs/organismes/organisme" group-by="nom">
                    <xsl:sort select="current-grouping-key()"/>
                    <organisme>
                        <nom>
                            <xsl:value-of select="current-grouping-key()"/>
                        </nom>
                        <xsl:for-each select="current-group()">
                            <infos>
                                <xsl:value-of select="idEAD"/>
                                <xsl:text> [cote </xsl:text>
                                <xsl:value-of select="cote"/>
                                <xsl:text>] (notice </xsl:text>
                                <xsl:value-of select="notice"/>
                                <xsl:text>) \\ date </xsl:text>
                                
                                <xsl:value-of select="date"/>
                                <xsl:if test="normalize-space(role)!='' and normalize-space(role)!='[]'">
                                    <xsl:text>// : </xsl:text>
                                    <xsl:value-of select="role"/>
                                </xsl:if>
                                
                                
                              
                            </infos>
                        </xsl:for-each>
                    </organisme>
                </xsl:for-each-group>
            </organismes>
        </xsl:variable>
        <xsl:result-document href="../xml-temp/liste-orgs-dedoublonnes.xml" method="xml"
            encoding="utf-8" indent="yes">
            <xsl:copy-of select="$merged-orgs"/>
        </xsl:result-document>
        <xsl:variable name="orgRoles">
            <roles>
                <xsl:for-each-group select="$merged-orgs/organismes/organisme/infos" group-by="
                    
                    if (contains(normalize-space(substring-after(., ':')), '- ajouté FC'))
                    then (normalize-space(substring-before(normalize-space(substring-after(., ':')), '- ajouté FC')))
                    
                    else (normalize-space(substring-after(., ':')))
                    
                    
                    ">
                    <xsl:sort select="current-grouping-key()"/>
                    <role><xsl:value-of select="current-grouping-key()"/></role>
                    
                    
                </xsl:for-each-group>
            </roles>
        </xsl:variable>
        <xsl:result-document href="../xml-temp/liste-org-roles-all.xml" method="xml"
            encoding="utf-8" indent="yes">
            <xsl:copy-of select="$orgRoles"/>
        </xsl:result-document>
       <xsl:result-document href="../output-rdf/organismes-all.rdf" method="xml" encoding="utf-8" indent="yes">
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
                xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
                
                <xsl:for-each
                    select="$merged-orgs/organismes/organisme">
                    <xsl:sort select="nom" lang="fr"/>
                    <!-- [auteur] Officialité de Paris (tribunal ; 11..-17..) [[] ; 185265235 ; [] ; Q99775030]-->
                    <!-- <Personnes_morales>[auteur] Collège des Cholets (collectivité ; 1292-1763) [[] ; 067074472 ; [] ; Q2983809]</Personnes_morales>-->
                    <!-- <Personne_morale>[auteur] Chapitre de l'Église de Paris | [destinataire] Parlement de Paris</Personne_morale>-->
                    <!-- Méthodologie durant le test : 
[role] CorporateBodyName (CorporateBody_type ; YYYY-YYYY) [n°ISNI ; n°IdRef ; n°referentiel_AN ; n°wikidata]
A remplir en renseignant dans cet ordre et en suivant scrupuleusement les signes servant de séparateurs :
1.	le type de personne morale par rapport au document décrit en s’appuyant sur le référentiel « role » (exemple : [auteur])
2.	le nom de la personne morale avec entre parenthèses l’activité principale de la personne morale au moment où le document a été rédigé (exemple : Officialité de Paris (tribunal ; 11..-17..))
3.	les numéros identifiants la personne dans les grands référentiels, entre crochet et toujours dans cet ordre et de la manière suivante [n°ISNI ; n°IdRef ; n°referentiel_AN ; n°wikidata] (exemple : [[] ; 185265235 ; [] ; Q99775030]).-->
                   <!-- <xsl:variable name="myName">
                        <xsl:value-of select="if (contains(nom, '('))
                            then normalize-space(substring-before(nom, '('))
                            
                            else normalize-space(nom)"/>
                    </xsl:variable>-->
                    <xsl:variable name="myName">
                        <xsl:choose>
                            <!--<xsl:when test="starts-with(nom, '[')">
                                <xsl:value-of select="normalize-space(substring-before(nom, '('))"/>
                            </xsl:when>-->
                            <xsl:when test="not(contains(nom, '('))">
                                <xsl:value-of select="normalize-space(replace(nom, $apos, '’'))"/> 
                            </xsl:when>
                            <xsl:when
                                test="ends-with(normalize-space(nom), '([] ; [])') or ends-with(normalize-space(nom), '([] ; [])') or ends-with(normalize-space(nom), '([])')">
                                
                                <xsl:value-of select="normalize-space(replace(substring-before(nom, '('), $apos, '’'))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!--<xsl:variable name="str"
                                    select="
                                        if (ends-with(normalize-space(substring-before(nom, ')')), ' ; []'))
                                        then
                                            (
                                            
                                            concat(normalize-space(substring-before(nom, ' ; []')), ')')
                                            )
                                        
                                        else
                                            (
                                            
                                            
                                            concat(normalize-space(substring-before(nom, ')')), ')')
                                            
                                            )
                                        "/>-->
                                <xsl:variable name="str">
                                    <xsl:choose>
                                        <xsl:when test="ends-with(normalize-space(substring-before(nom, ')')), ' ; []')">
                                            <xsl:value-of select="concat(normalize-space(replace(substring-before(nom, ' ; []'), $apos, '’')), ')')"/>
                                        </xsl:when>
                                        <!-- PIERRE Orage ([] ; 14..-15..)-->
                                        <xsl:when test="starts-with(normalize-space(substring-after(nom, '(')), '[]')">
                                            <xsl:value-of select="concat(normalize-space(replace(substring-before(nom, '('), $apos, '’')), ' (', normalize-space(substring-before(substring-after(nom,  ';'), ')')), ')')"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="concat(normalize-space(replace(substring-before(nom, ')'), $apos, '’')), ')')"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                
                                <xsl:value-of select="normalize-space($str)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <rico:CorporateBody>
                        <xsl:attribute name="rdf:about">
                            <xsl:value-of select="concat('corporateBody/', encode-for-uri($myName))"/>
                        </xsl:attribute>
                        <rdfs:label xml:lang="fr">
                            <xsl:value-of select="$myName"/>
                        </rdfs:label>
                        <rico:name xml:lang="fr">
                            <xsl:value-of select="$myName"/>
                        </rico:name>
                      
                        <xsl:variable name="refsString"
                            select="normalize-space(substring-after(nom, ')'))"/>
                        <!-- <xsl:for-each select="tokenize($refsString, ' ;')[normalize-space(.)!='' and normalize-space(.)!='[]' and normalize-space(.)!='[[]']">-->
                        <xsl:for-each select="tokenize($refsString, ';')">
                            <!-- isni, idref, an, wikidata-->
                            <xsl:choose>
                                <xsl:when test="position() = 1 and normalize-space(.) != '[[]'">
                                    <!-- isni-->
                                    <!--<isni:identifierValid><xsl:value-of select="normalize-space(.)"/></isni:identifierValid>-->
                                    <owl:sameAs>
                                        <xsl:attribute name="rdf:resource">
                                            <xsl:value-of
                                                select="concat('http://isni.org/isni/', normalize-space(replace(substring-after(., '['), ' ', '')))"
                                            />
                                        </xsl:attribute>
                                    </owl:sameAs>
                                </xsl:when>
                                <xsl:when test="position() = 2 and normalize-space(.) != '[]'">
                                    <!-- idref-->
                                    <!-- http://www.idref.fr/086043064/id-->
                                    <owl:sameAs>
                                        <xsl:attribute name="rdf:resource">
                                            <xsl:value-of
                                                select="concat('http://www.idref.fr/', normalize-space(.), '/id')"
                                            />
                                        </xsl:attribute>
                                    </owl:sameAs>
                                </xsl:when>
                                <xsl:when test="position() = 3 and normalize-space(.) != '[]'">
                                    <!-- an-->
                                    <!-- [[] ; 253188458 ; FRAN_NP_012635 ; []]-->
                                    <xsl:if test="starts-with(normalize-space(.), 'FRAN_NP')">
                                        <owl:sameAs>
                                            <xsl:attribute name="rdf:resource">
                                                <xsl:value-of
                                                    select="concat('http://data.archives-nationales.culture.gouv.fr/agent/', normalize-space(substring-after(., 'FRAN_NP_')))"
                                                />
                                            </xsl:attribute>
                                        </owl:sameAs>
                                    </xsl:if>
                                    <xsl:if test="starts-with(normalize-space(.), 'Q')">
                                        <owl:sameAs>
                                            <xsl:attribute name="rdf:resource">
                                                <xsl:value-of
                                                    select="concat('http://www.wikidata.org/entity/', normalize-space(substring-before(., ']')))"
                                                />
                                            </xsl:attribute>
                                        </owl:sameAs>
                                    </xsl:if>
                                </xsl:when>
                                <xsl:when test="position() = 4 and normalize-space(.) != '[]]'">
                                    <!-- wikidata-->
                                    <!-- https://www.wikidata.org/entity/Q352  http://www.wikidata.org/entity/Q352-->
                                    <xsl:if test="starts-with(normalize-space(.), 'FRAN_NP')">
                                        <owl:sameAs>
                                            <xsl:attribute name="rdf:resource">
                                                <xsl:value-of
                                                    select="concat('http://data.archives-nationales.culture.gouv.fr/agent/', normalize-space(substring-after(., 'FRAN_NP_')))"
                                                />
                                            </xsl:attribute>
                                        </owl:sameAs>
                                    </xsl:if>
                                    <xsl:if test="starts-with(normalize-space(.), 'Q')">
                                        <owl:sameAs>
                                            <xsl:attribute name="rdf:resource">
                                                <xsl:value-of
                                                    select="concat('http://www.wikidata.org/entity/', normalize-space(substring-before(., ']')))"
                                                />
                                            </xsl:attribute>
                                        </owl:sameAs>
                                    </xsl:if>
                                </xsl:when>
                            </xsl:choose>
                            <!--</xsl:for-each>-->
                            
                            
                            
                        </xsl:for-each>
                        <!-- relation avec doct-->
                        <xsl:for-each select="infos">
                         
                            <xsl:variable name="ORESMDocId">
                                <xsl:value-of select="concat('or-', substring-before(substring-after(., 'notice '), ')'))"/>
                            </xsl:variable>
                            <xsl:variable name="roleStr" select="normalize-space(substring-after(., ':'))"/>
                            
                            <xsl:variable name="trueRoleStr">
                                <xsl:choose>
                                    <xsl:when test="ends-with($roleStr, '- ajouté FC')">
                                        <xsl:value-of select="normalize-space(substring-before($roleStr, '- ajouté FC'))"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$roleStr"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:for-each select="tokenize($trueRoleStr, '/')">
                                <xsl:choose>
                                    <xsl:when test="normalize-space(.)='personne concernée'">
                                        <rico:isOrWasSubjectOf rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='auteur'">
                                        <rico:isAuthorOf rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='rédacteur'">
                                        <oresm-onto:estRedacteurDe rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='destinataire'">
                                        <rico:isAddresseeOf rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='bénéficiaire'">
                                        <oresm-onto:estBeneficiaireActeConsigneDans rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='donateur'">
                                        <oresm-onto:estDonateurActeConsigneDans rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='testateur'">
                                        <oresm-onto:estTestateurDe rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <!-- ajout cas de "testataire" trouvé à 8 reprises pour les personnes morales ; en fait il s'gait sauf erreur du bénéficiaire d'un testament-->
                                    <xsl:when test="normalize-space(.)='testataire'">
                                        <oresm-onto:estBeneficiaireActeConsigneDans rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='donataire'">
                                        <oresm-onto:estDonataireActeConsigneDans rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                    <xsl:when test="normalize-space(.)='témoin'">
                                        <oresm-onto:estTemoinDe rdf:resource="recordResource/{$ORESMDocId}"/>
                                    </xsl:when>
                                </xsl:choose>
                            </xsl:for-each>
                            
                        </xsl:for-each>
                    </rico:CorporateBody>
                </xsl:for-each>
                
            </rdf:RDF>
        </xsl:result-document>
        
        <!--### LIEUX DE PASSAGE DES ACTES ###-->
        
        <!-- <Lieu_de_passage_acte_forme_litteraire>Collège des Cholets</Lieu_de_passage_acte_forme_litteraire>
        <Lieu_de_passage_acte_forme_normalisee>Collège des Cholets</Lieu_de_passage_acte_forme_normalisee>
        <Lieu_de_passage_acte_coordonnees_geographiques>48.84736218383409, 2.3447759557297774</Lieu_de_passage_acte_coordonnees_geographiques>
        <Lieu_de_passage_acte_code_INSEE_ou_code_postal>75105</Lieu_de_passage_acte_code_INSEE_ou_code_postal>-->
        <xsl:result-document href="../temp-rdf/lieux-de-passage-actes-all.rdf" method="xml" encoding="utf-8" indent="yes">
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
                xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
                xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
                <xsl:for-each-group select="
                    $fichiersDept/documents/document/Lieu_de_passage_de_l_acte__forme_normalisée_[normalize-space(.)!=''] | $fichiersDept/documents/document[normalize-space(Lieu_de_passage_de_l_acte__forme_normalisée_)='' and normalize-space(Lieu_de_passage_de_l_acte__forme_littérale_)!='']/Lieu_de_passage_de_l_acte__forme_littérale_" 
                    
                    
                    group-by="concat(normalize-space(.), ' | ', normalize-space(following-sibling::Coordonnées_géographiques), ' % ', normalize-space(following-sibling::Code_INSEE_ou_code_postal), ' // ', normalize-space(following-sibling::Pays), ' !! ', normalize-space(preceding-sibling::Lieu_de_passage_de_l_acte__forme_littérale_))
                   ">
            <xsl:sort select="current-grouping-key()"/>
                    <xsl:if test="current-grouping-key()!=''">
            <rico:Place>
                <xsl:attribute name="rdf:about">
                    <xsl:value-of select="concat('place/', encode-for-uri(substring-before(current-grouping-key(), ' |')))"/>
                </xsl:attribute>
                <rdfs:label xml:lang="fr">
                    <xsl:value-of select="normalize-space(substring-before(current-grouping-key(), ' |'))"/>
                    <xsl:if test="normalize-space(substring-before(substring-after(current-grouping-key(), ' //'), '!!'))!='' and normalize-space(substring-before(substring-after(current-grouping-key(), ' //'), '!!'))!='75000'">
                        <xsl:value-of select="concat(' (', normalize-space(substring-before(substring-after(current-grouping-key(), ' //'), '!!')),')')"/>
                    </xsl:if>
                </rdfs:label>
                <rico:name xml:lang="fr"> <xsl:value-of select="normalize-space(substring-before(current-grouping-key(), ' |'))"/>
                    <xsl:if test="normalize-space(substring-before(substring-after(current-grouping-key(), ' //'), '!!'))!='' and normalize-space(substring-before(substring-after(current-grouping-key(), ' //'), '!!'))!='75000'">
                        <xsl:value-of select="concat(' (', normalize-space(substring-before(substring-after(current-grouping-key(), ' //'), '!!')),')')"/>
                    </xsl:if>
                </rico:name>
                
                
                <!-- Volonté de garder la forme littérale du lieu quand on la connait, a voir ce qu'on en fait
                    <xsl:if test="normalize-space(substring-after(current-grouping-key(), ' !!'))!='' and normalize-space(substring-after(current-grouping-key(), ' !!'))!=normalize-space(substring-before(current-grouping-key(), ' |'))">
                    <rico:name xml:lang="fr">
                        <xsl:value-of select="normalize-space(substring-after(current-grouping-key(), ' !!'))"/>
                    </rico:name>
                </xsl:if>
                -->

                <xsl:if test="normalize-space(substring-before(substring-after(current-grouping-key(), '|'), '%'))!=''">
                    <xsl:variable name="coords" select="normalize-space(substring-before(substring-after(current-grouping-key(), '|'), '%'))"/>
                    <rico:latitude>
                        <xsl:value-of select="normalize-space(substring-before($coords, ','))"/>
                    </rico:latitude>
                    <rico:longitude>
                        <xsl:value-of select="normalize-space(substring-after($coords, ','))"/>
                    </rico:longitude>
                    
                    
                </xsl:if>
                <xsl:for-each select="current-group()">
                    <xsl:variable name="ORESMDocId">
                        <xsl:value-of select="concat('or-', ancestor::documents/@id, '-', count(parent::document/preceding-sibling::document)+1) "/>
                    </xsl:variable>
                    <oresm-onto:estLieudePassageActe rdf:resource="recordResource/{$ORESMDocId}"/>
                </xsl:for-each>
            </rico:Place>
                    </xsl:if>
        </xsl:for-each-group>
            </rdf:RDF>
        </xsl:result-document>
       
       <xsl:variable name="tempLieux">
           <lieux>
               <xsl:for-each select="$fichiersDept/documents/document/Lieux_cités_dans_l_analyse__forme_normalisée_[normalize-space(.) !=''] | 
                   $fichiersDept/documents/document[(normalize-space(Lieux_cités_dans_l_analyse__forme_normalisée_)  = '' or 
                   not(Lieux_cités_dans_l_analyse__forme_normalisée_)) and normalize-space(./Lieux_cités_dans_l_analyse__forme_rédigée_) != '']/Lieux_cités_dans_l_analyse__forme_rédigée_">
                   
                    <xsl:variable name="idEAD" select="normalize-space(replace(parent::document/Identifiant_du_guide, '—', '--'))"/>
                    <!--   <xsl:variable name="doc" select="normalize-space(parent::document/Identifiant_du_guide)"/>-->
                    <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                    
                    
                    <xsl:variable name="notice"
                        select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                    
                    <xsl:variable name="document" select="parent::document"/>
                    
                    <xsl:for-each select="tokenize(.,'\|')[normalize-space(.) != '[]']">
                        <xsl:variable name="position" select="position()"/>
                        <xsl:variable name="coordonnees" select="tokenize($document/Coordonnées_géographiques_des_lieux_cités_dans_l_analyse,'\|')[position() = $position]"/>
                        <xsl:variable name="insee" select="tokenize($document/Code_INSEE_ou_code_postal_des_lieux_cités_dans_l_analyse,'\|')[position() = $position]"/>
                        <xsl:variable name="pays" select="tokenize($document/Pays_identifiant_les_lieux_cités_dans_l_analyse,'\|')[position() = $position]"/>
                        <lieu>
                            <nom>
                                <xsl:value-of select="normalize-space(.)"/>
                            </nom>
                            
                            <infos>
                                <xsl:value-of select="$idEAD"/>
                                <xsl:text> [cote </xsl:text>
                                <xsl:value-of select="$cote"/>
                                <xsl:text>] (notice </xsl:text>
                                <xsl:value-of select="$notice"/>
                                <xsl:text>)</xsl:text>
                            </infos>
                            <xsl:if test="$coordonnees != ''">
                                <coordonnees><xsl:value-of select="normalize-space($coordonnees)"/></coordonnees>
                            </xsl:if>
                            
                        </lieu>
                    </xsl:for-each>
                    
                </xsl:for-each>
           </lieux>
       </xsl:variable>
       <xsl:result-document href="../xml-temp/liste-cite-analyse.xml" method="xml"
           encoding="utf-8" indent="yes">
           <xsl:copy-of select="$tempLieux"/>
       </xsl:result-document>
       
       <xsl:variable name="tempLieuxDedoublonne">
           <lieux>
                <xsl:for-each-group select="$tempLieux/lieux/lieu" group-by="nom">
                   <lieu>
                        <nom><xsl:value-of select="current-grouping-key()"/></nom>
                       <xsl:if test="current-group()/coordonnees">
                           <coordonnees><xsl:value-of select="current-group()[coordonnees][1]/coordonnees"/></coordonnees>
                       </xsl:if>
                       
                        <xsl:for-each select="current-group()/infos">
                            <infos><xsl:copy-of select="."/></infos>
                        </xsl:for-each>
                   </lieu>
                </xsl:for-each-group>
           </lieux>
       </xsl:variable>
       <xsl:result-document href="../xml-temp/liste-cites-analyse-dedoublonnes.xml" method="xml"
           encoding="utf-8" indent="yes">
           <xsl:copy-of select="$tempLieuxDedoublonne"/>
       </xsl:result-document>
       
       <xsl:result-document href="../temp-rdf/lieux-cite-analyse.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               
               <xsl:for-each select="$tempLieuxDedoublonne/lieux/lieu">
                   <xsl:sort select="./nom/text()" order="descending" data-type="text"/>
                   <rico:Place rdf:about="place/{encode-for-uri(./nom)}">
                       <rdfs:label xml:lang="fr"><xsl:value-of select="./nom"/></rdfs:label>
                       <rico:name xml:lang="fr"><xsl:value-of select="./nom"/></rico:name>
                       
                       <xsl:if test="coordonnees">
                           <rico:latitude><xsl:value-of select="normalize-space(substring-before(coordonnees,','))"/></rico:latitude>
                           <rico:longitude><xsl:value-of select="normalize-space(substring-after(coordonnees,','))"/></rico:longitude>    
                       </xsl:if>
                       
                       
                       <xsl:for-each select="./infos">
                           <xsl:variable name="OresmID" select="concat('or-',substring-before(substring-after(./infos,'notice '),')'))"/>
                           <rico:isPlaceAssociatedWith rdf:resource="recordResource/{$OresmID}"></rico:isPlaceAssociatedWith>
                       </xsl:for-each>
                       
                   </rico:Place>
               </xsl:for-each>
           </rdf:RDF>
       </xsl:result-document>
       
       
       <!-- ### supports ### -->
       <xsl:variable name="supports">
           
                <supports>
                   
                        <xsl:for-each select="$fichiersDept/documents/document/Support[normalize-space(.)!='']">
                            <xsl:sort lang="fr" select="normalize-space(.)"></xsl:sort>
                          <!--  <xsl:variable name="doc" select="normalize-space(parent::document/Identifiant_du_guide)"/>-->
                            <xsl:variable name="idEAD" select="normalize-space(replace(parent::document/Identifiant_du_guide, '—', '--'))"/>
                            <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                            
                            <xsl:variable name="notice"
                                select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                            <xsl:variable name="date" select="
                                if (normalize-space(parent::document/Date__forme_normalisée_)!='')
                                
                                then normalize-space(parent::document/Date__forme_normalisée_)
                                
                                else (
                                
                                if (normalize-space(parent::document/Date__forme_rédigée_)!='')
                                
                                then (
                                normalize-space(parent::document/Date__forme_rédigée_))
                                
                                else ('sans date')
                                )
                                
                                "/>
                            
                            <xsl:for-each select="tokenize(., '\|')[. != '']">
                            <support>
                                <nom>
                                    <xsl:value-of select="
                                        if(normalize-space(lower-case(.))!='parch.')
                                        then(normalize-space(.))
                                        else('parchemin')
                                        "/>
                                </nom>
                              
                                    <infos>
                                        <xsl:value-of select="$idEAD"/>
                                        <xsl:text> [cote </xsl:text>
                                        <xsl:value-of select="$cote"/>
                                        <xsl:text>] (notice </xsl:text>
                                        <xsl:value-of select="$notice"/>
                                        <xsl:text>) \\ date </xsl:text>
                                        
                                        <xsl:value-of select="$date"/>
                                        
                                        
                                        
                                        
                                    </infos>
                                
                            </support>
                        </xsl:for-each>
                        
               
                 
                        </xsl:for-each>
                </supports>
       </xsl:variable>
       <xsl:result-document href="../xml-temp/supports.xml"  method="xml" encoding="utf-8" indent="yes">
           <xsl:copy-of select="$supports"></xsl:copy-of>
       </xsl:result-document>
       <xsl:result-document href="../output-rdf/supports-all.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               <xsl:for-each-group select="$supports/supports/support" group-by="lower-case(nom)">
                   <xsl:sort select="current-grouping-key()" lang="fr"/>
                   <rico:CarrierType rdf:about="carrierType/{encode-for-uri(normalize-space(current-grouping-key()))}">
                       <rdfs:label xml:lang="fr"><xsl:value-of select="current-grouping-key()"/></rdfs:label>
                      
                       <xsl:if test="$supportsAN/skos:Concept[skos:prefLabel=current-grouping-key()]">
                           <owl:sameAs>
                               <xsl:attribute name="rdf:resource">
                                   <xsl:value-of select="concat($supportsAN/@xml:base, $supportsAN/skos:Concept[skos:prefLabel=current-grouping-key()]/@rdf:about)"/>
                               </xsl:attribute>
                               
                           </owl:sameAs>
                       </xsl:if> 
                       <xsl:for-each select="current-group()">
                           <xsl:variable name="ORESMDocId">
                             <!--  <xsl:value-of select="concat('or-', count(parent::document/preceding-sibling::document)+1) "/>-->
                               <xsl:value-of select="concat('or-', substring-before(substring-after(infos, 'notice '), ')'))"/>
                           </xsl:variable>
                           <rico:isCarrierTypeOf rdf:resource="instantiation/{$ORESMDocId}"/>
                       </xsl:for-each>
                   </rico:CarrierType>
                  
               </xsl:for-each-group>
               
               
           </rdf:RDF>
           
       </xsl:result-document>
       
       <!--### Etats et types de documents ###-->
       <!-- on doit ici s'occuper du contenu des champs Status et Type_de_document en même temps, puisque les règles ont changé. D'autre part, ces données devront être regénérées après que les référentiels concernés aux AN auront été enrichis dans le cadre du projet ; cela je vais m'en occuper-->
       
       <xsl:variable name="typesdoct">
          
           <typesDeDocuments>
               
               <xsl:for-each select="$fichiersDept/documents/document/Type_de_document[normalize-space(.)!=''] | $fichiersDept/documents/document/Statut[normalize-space(.)!='']">
                   <xsl:sort lang="fr" select="normalize-space(.)"></xsl:sort>
                   <xsl:variable name="idEAD" select="normalize-space(replace(parent::document/Identifiant_du_guide, '—', '--'))"/>
                <!--   <xsl:variable name="doc" select="normalize-space(parent::document/Identifiant_du_guide)"/>-->
                   <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                
                   <xsl:variable name="notice"
                       select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                   <xsl:variable name="date" select="
                       if (normalize-space(parent::document/Date__forme_normalisée_)!='')
                       
                       then normalize-space(parent::document/Date__forme_normalisée_)
                       
                       else (
                       
                       if (normalize-space(parent::document/Date__forme_rédigée_)!='')
                       
                       then (
                       normalize-space(parent::document/Date__forme_rédigée_))
                       
                       else ('sans date')
                       )
                       
                       "/>
                   
                   <xsl:for-each select="tokenize(., '\|')[. != '']">
                       <type>
                           <nom>
                               <xsl:value-of select="normalize-space(.)"/>
                           </nom>
                           
                           <infos>
                               <xsl:value-of select="$idEAD"/>
                               <xsl:text> [cote </xsl:text>
                               <xsl:value-of select="$cote"/>
                               <xsl:text>] (notice </xsl:text>
                               <xsl:value-of select="$notice"/>
                               <xsl:text>) \\ date </xsl:text>
                               
                               <xsl:value-of select="$date"/>
                               
                               
                               
                               
                           </infos>
                           
                       </type>
                   </xsl:for-each>
               </xsl:for-each>
               <xsl:for-each select="$fichiersDept/documents/document/Remarques[matches(.,'type de l.acte','i')]">
                   <!-- Pas de cote associée aux documents copié dont on s'occupe dans les Remarques, pas plusieurs documents copiés donc forcèment luri sera avec vir1 -->
                   <xsl:variable name="notice" select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1,'-virt1')"/>
                   <xsl:for-each select="tokenize(.,'\|')">
                       <xsl:if test="matches(.,'type de l.acte','i')">
                           <type>
                               <nom><xsl:value-of select="normalize-space(substring-after(.,': '))"/></nom>
                               <infos>(notice <xsl:value-of select="$notice"/>)</infos>
                           </type>
                       </xsl:if>
                   </xsl:for-each>
               </xsl:for-each>
           </typesDeDocuments>
       </xsl:variable>
       <xsl:result-document href="../xml-temp/typesDeDocuments.xml"  method="xml" encoding="utf-8" indent="yes">
           <xsl:copy-of select="$typesdoct"></xsl:copy-of>
       </xsl:result-document>
       <xsl:result-document href="../output-rdf/etats-et-types-de-documents-all.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               <xsl:for-each-group select="$typesdoct/typesDeDocuments/type" group-by="lower-case(replace(nom,   $apos, '’'))">
                   <xsl:sort select="current-grouping-key()" lang="fr"/>
                   
                   <xsl:variable name="classe">
                       <xsl:choose>
                           <xsl:when test="$etatsAN/skos:Concept[skos:prefLabel=current-grouping-key()]">
                               <xsl:text>RecordState</xsl:text>
                           </xsl:when>
                       </xsl:choose>
                       <xsl:choose>
                           <xsl:when test="$typesDocAN/skos:Concept[skos:prefLabel=current-grouping-key()]">
                               <xsl:text>DocumentaryFormType</xsl:text>
                           </xsl:when>
                       </xsl:choose>
                   </xsl:variable>
                   <rico:Type rdf:about="type/{encode-for-uri(normalize-space(current-grouping-key()))}">
                       <rdfs:label xml:lang="fr"><xsl:value-of select="current-grouping-key()"/></rdfs:label>
                       <xsl:if test="$classe!=''">
                           <rdf:type rdf:resource="{concat('rico:', $classe)}"/>
                           <owl:sameAs>
                               <xsl:attribute name="rdf:resource">
                                   <xsl:value-of select="
                                       if ($classe='DocumentaryFormType')
                                       
                                       then (concat($typesDocAN/@xml:base, $typesDocAN/skos:Concept[skos:prefLabel=current-grouping-key()]/@rdf:about))
                                       
                                       else(concat($etatsAN/@xml:base, $etatsAN/skos:Concept[skos:prefLabel=current-grouping-key()]/@rdf:about))
                                       "/>
                               </xsl:attribute>
                           </owl:sameAs>
                       </xsl:if>
                           
                     
                       <xsl:for-each select="current-group()">
                           <xsl:variable name="ORESMDocId">
                           
                               <xsl:value-of select="concat('or-', substring-before(substring-after(infos, 'notice '), ')'))"/>
                           </xsl:variable>
                           
                           <xsl:choose>
                               <xsl:when test="$classe!=''">
                                   <xsl:choose>
                                       <xsl:when test="$classe='RecordState'">
                                           <rico:isRecordStateOf rdf:resource="recordResource/{$ORESMDocId}"/>
                                       </xsl:when>
                                       <xsl:when test="$classe='DocumentaryFormType'">
                                           <rico:isDocumentaryFormTypeOf rdf:resource="recordResource/{$ORESMDocId}"/>
                                       </xsl:when>
                                   </xsl:choose>
                               </xsl:when>
                               <xsl:otherwise>
                                   <rico:isOrWasCategoryOf rdf:resource="recordResource/{$ORESMDocId}"/>
                               </xsl:otherwise>
                           </xsl:choose>
                       </xsl:for-each>
                   </rico:Type>
                   
               </xsl:for-each-group>
               
               
           </rdf:RDF>
           
       </xsl:result-document>
        
       <!-- ### les cotes actuelles -->
       <xsl:variable name="cotes-actuelles">
           <cotes-actuelles>
               <!-- Bibliothèque de la Sorbonne (Paris), FRAN, FRAD060, FRAD077 -->
                   
               <xsl:for-each select="$fichiersDept/documents/document/Cote_actuelle[normalize-space()!='']">
                  <!-- <xsl:variable name="doc" select="normalize-space(parent::document/Identifiant_du_guide)"/>-->
                   <xsl:variable name="idEAD" select="normalize-space(replace(parent::document/Identifiant_du_guide, '—', '--'))"/>
                   <xsl:variable name="notice"
                       select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                          
                               <cote-actuelle>
                                   <cote>
                                       <xsl:value-of select="normalize-space(.)"/>
                                   </cote>
                                   
                                   <idEAD>
                                       <xsl:value-of select="$idEAD"/>
                                   </idEAD>
                                 
                                   <notice>
                                       <xsl:value-of select="$notice"/>
                                   </notice>
                                   
                                   <xsl:if test="contains(following-sibling::Remarques,'cette cote a été forgée')">
                                       <note><xsl:value-of select="tokenize(following-sibling::Remarques,'\|')[contains(.,'cette cote a été forgée')]"/></note>
                                   </xsl:if>
                                   
                               </cote-actuelle>
                       </xsl:for-each>
               
               <xsl:for-each select="$fichiersDept/documents/document/Acte_original_cote_actuelle[normalize-space(.) != '']">
                   <xsl:variable name="document" select="parent::document"/>
                   <xsl:for-each select="tokenize(.,'\|')">
                       <xsl:variable name="position" select="position()"/>
                       <xsl:variable name="cote_original" select="normalize-space(.)"/>
                       <xsl:variable name="analyseOriginale" select="normalize-space(tokenize($document/Acte_original_analyse,'\|')[position() = $position])"/>
                       <xsl:variable name="dateOriginale" select="normalize-space(tokenize($document/Acte_original_date__forme_normalisée_,'\|')[position() = $position])"/>
                       <xsl:if test="not($fichiersDept/documents/document/Cote_actuelle[normalize-space(.) = $cote_original])
                           and count($document/preceding-sibling::document[Acte_original_cote_actuelle[count(tokenize(.,'\|')[normalize-space(.) = $cote_original]) > 0]]) = 0
                           and count($document/preceding-sibling::document[Acte_original_analyse[count(tokenize(.,'\|')[normalize-space(.)=$analyseOriginale]) > 0] 
                           and Acte_original_date__forme_normalisée_[count(tokenize(.,'\|')[normalize-space(.)=$dateOriginale]) > 0]]) = 0">
                           
                           <xsl:if test="$cote_original != '[]' and not(starts-with($cote_original,'lost')) ">
                               <cote-actuelle>
                                   <cote><xsl:value-of select="$cote_original"/></cote>
                                   <notice><xsl:value-of select="concat($document/ancestor::documents/@id,'-',count($document/preceding-sibling::document)+1,'-virt',$position)"/></notice>
                               </cote-actuelle>
                           </xsl:if>
                       </xsl:if>
                       
                   </xsl:for-each>
               </xsl:for-each>
                   
               
           </cotes-actuelles>
       </xsl:variable>
       
        <xsl:result-document href="../xml-temp/cotes-actuelles.xml">
            <xsl:copy-of select="$cotes-actuelles"/>
        </xsl:result-document>
       <xsl:result-document href="../output-rdf/cotes-actuelles-all.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               <xsl:for-each-group select="$cotes-actuelles/cotes-actuelles/cote-actuelle" group-by="normalize-space(cote)">
                   <xsl:sort select="current-grouping-key()" lang="fr"/>
                   <xsl:variable name="key" select="current-grouping-key()"/>
                   <xsl:variable name="lieuConservation">
                       <xsl:choose>
                           <xsl:when test="starts-with($key, 'FRAN')">
                               <xsl:text>FRAN</xsl:text>
                           </xsl:when>
                           <xsl:when test="starts-with($key, 'FRAD077')">
                               <xsl:text>FRAD077</xsl:text>
                           </xsl:when>
                           <xsl:when test="starts-with($key, 'FRAD060')">
                               <xsl:text>FRAD060</xsl:text>
                           </xsl:when>
                           <xsl:when test="starts-with($key, 'Bibliothèque')">
                               <xsl:text>BIS</xsl:text>
                           </xsl:when>
                           
                       </xsl:choose>
                   </xsl:variable>
                   <xsl:variable name="trueId">
                       <xsl:choose>
                           <xsl:when test="$lieuConservation='FRAN'">
                               <xsl:value-of select="
                                   
                                   if (starts-with($key, 'FRAN '))
                                   
                                   then normalize-space(substring-after($key, 'FRAN '))
                                   
                                   else (normalize-space(substring-after($key, 'FRAN/')))
                                   "/>
                           </xsl:when>
                           <xsl:when test="$lieuConservation='FRAD077'">
                               <xsl:value-of select="
                                   normalize-space(substring-after($key, 'FRAD077/'))
                                   "/>
                           </xsl:when>
                           <xsl:when test="$lieuConservation='FRAD060'">
                               <xsl:value-of select="
                                   normalize-space(substring-after($key, 'FRAD060/'))
                                   "/>
                           </xsl:when>
                           
                           <xsl:when test="$lieuConservation='BIS'">
                               <xsl:value-of select="
                                   normalize-space(substring-after($key, 'Bibliothèque de la Sorbonne (Paris),'))
                                   "/>
                           </xsl:when>
                           <xsl:otherwise>
                               <xsl:value-of select="$key"/>
                           </xsl:otherwise>
                       </xsl:choose>
                   </xsl:variable>
                
                   <rico:Identifier>
                       <xsl:attribute name="rdf:about">
                           <xsl:value-of select="concat('identifier/', $lieuConservation, '-', encode-for-uri($trueId))"/>
                       </xsl:attribute>
                       
                       
                       <rdfs:label xml:lang="fr"><xsl:value-of select="concat($lieuConservation, 
                           if ($lieuConservation!='') then (' ') else (),
                           
                            $trueId)"/></rdfs:label>
                       
                      
                       <xsl:for-each select="current-group()">
                           
                           <xsl:variable name="ORESMDocId">
                                 <xsl:value-of select="concat('or-', notice) "/>
                              
                              
                           </xsl:variable>
                           <oresm-onto:estCoteActuelleDe rdf:resource="instantiation/{$ORESMDocId}"/>
                           <xsl:if test="note">
                               <rico:descriptiveNote><xsl:value-of select="note"/></rico:descriptiveNote>
                           </xsl:if>
                       </xsl:for-each>

                   </rico:Identifier>
                   
               </xsl:for-each-group>
               
               
           </rdf:RDF>
           
       </xsl:result-document>
       <!--### LES ANCIENNES COTES ### -->
       
       <!-- Traité refait différement en ne se souciant de rien si ce n'est individiulaiser les champs et liés la date avec si il y en a une -->
       <!-- VOIR COMMENT INDIQUER L'INVENTAIRE D'OU VIENT L'ANCIENNE COTE SUR HISTORIQUE DE CONSERVATION -->
       
       <xsl:variable name="anciennes-cotations">
           <anciennes-cotes>
               <xsl:for-each select="$fichiersDept/documents/document/Anciennes_cotations[normalize-space(.)!='']">
                   <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                   
                   <xsl:variable name="notice" select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                   
                   <xsl:for-each select="tokenize(.,'\|')[. != '']">
                        <ancienne-cote>
                            <nom><xsl:value-of select="normalize-space(.)"/></nom>
                            <cote-actuelle><xsl:value-of select="$cote"/></cote-actuelle>
                            <notice><xsl:value-of select="$notice"/></notice>
                        </ancienne-cote>
                   </xsl:for-each>
               </xsl:for-each>
               
               
               
               <xsl:for-each select="$fichiersDept/documents/document/Historique_de_la_conservation[normalize-space(.)!='']">
                   <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                   <xsl:variable name="notice" select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                   
                   <xsl:for-each select="tokenize(.,'\|')">
                       <xsl:analyze-string select="replace(.,'--',';')" regex="([^;]+);([^;]+);([^;]+);([^;]+)">
                           <xsl:matching-substring>
                               <xsl:if test="not(contains((regex-group(3)),'[]'))">
                                   <ancienne-cote>
                                        <nom><xsl:value-of select="concat(normalize-space(regex-group(3)),'(',regex-group(2),')')"/></nom>
                                        <cote-actuelle><xsl:value-of select="$cote"/></cote-actuelle>
                                        <notice><xsl:value-of select="$notice"/></notice>
                                        <inventaire><xsl:value-of select="normalize-space(regex-group(4))"/></inventaire>
                                   </ancienne-cote>
                               </xsl:if>
                           </xsl:matching-substring>
                       </xsl:analyze-string>
                   </xsl:for-each>
                   
               </xsl:for-each>
           </anciennes-cotes>
       </xsl:variable>
       <xsl:result-document href="../xml-temp/cotes-anciennes.xml" method="xml" indent="yes" encoding="utf-8">
           <xsl:copy-of select="$anciennes-cotations"/>
       </xsl:result-document>
       <xsl:variable name="anciennes-cotations-dedoublonnees">
           <anciennes-cotes>
               <xsl:for-each-group select="$anciennes-cotations/anciennes-cotes/ancienne-cote" group-by="normalize-space(substring-before(nom,'('))">
                   <ancienne-cote>
                       <nom><xsl:value-of select="current-grouping-key()"/></nom>
                       <xsl:for-each select="current-group()">
                           <info><xsl:value-of select="cote-actuelle"/>||<xsl:value-of select="notice"/>::<xsl:value-of select="inventaire"/>
                               <xsl:if test="normalize-space(substring-before(substring-after(nom,'('),')'))!='[]'">
                                   <date><xsl:value-of select="normalize-space(substring-before(substring-after(nom,'('),')'))"/></date>
                               </xsl:if>
                           </info>
                       </xsl:for-each>
                   </ancienne-cote>
               </xsl:for-each-group>
           </anciennes-cotes>
       </xsl:variable> 
       <xsl:result-document href="../xml-temp/anciennes-cotes-dedoublonnees.xml" method="xml" indent="yes" encoding="utf-8">
            <xsl:copy-of select="$anciennes-cotations-dedoublonnees"/>
       </xsl:result-document>
       
       <xsl:result-document href="../output-rdf/anciennes-cotes-all.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               
               <xsl:for-each select="$anciennes-cotations-dedoublonnees/anciennes-cotes/ancienne-cote">
                   <xsl:sort select="nom"/>
                   <xsl:variable name="cote" select="normalize-space(nom)"/>
                   

                        <rico:Identifier rdf:about="identifier/{encode-for-uri($cote)}">
                            <rdfs:label xml:lang="fr"><xsl:value-of select="$cote"/></rdfs:label>
                            <rico:type xml:lang="fr">ancienne cotation d'acte</rico:type>
                            <xsl:for-each-group select="info" group-by="if(date) then(date) else('')">
                                <xsl:choose>
                                    <xsl:when test="current-grouping-key()!=''">
                                        <oresm-onto:identifierIsSourceOfIdentifierRelation rdf:resource="identifierRelation/{encode-for-uri(concat($cote,'-',normalize-space(date)))}"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:for-each select="current-group()">
                                            <oresm-onto:estCoteAncienneDe rdf:resource="instantiation/or-{encode-for-uri(normalize-space(substring-before(substring-after(.,'||'),'::')))}"/>
                                        </xsl:for-each>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each-group>
                        </rico:Identifier>
                   
                   <xsl:for-each-group select="info" group-by="date">
                       <oresm-onto:IdentifierRelation rdf:about="identifierRelation/{encode-for-uri(concat($cote,'-',current-grouping-key()))}">
                           <rico:date><xsl:value-of select="current-grouping-key()"/></rico:date>
                           <rico:descriptiveNote xml:lang="fr">Relation entre la cote <xsl:value-of select="$cote"/> et les instantiations qui l'ont utilisé dans la période "<xsl:value-of select="current-grouping-key()"/>".</rico:descriptiveNote>
                           <xsl:for-each select="current-group()">
                               <oresm-onto:identifierRelationHasTarget rdf:resource="instantiation/or-{encode-for-uri(normalize-space(substring-before(substring-after(.,'||'),'::')))}"/>
                           </xsl:for-each>
                           
                       </oresm-onto:IdentifierRelation>
                   </xsl:for-each-group>
                   
                   
               </xsl:for-each>
               
           </rdf:RDF>
       </xsl:result-document>
       
       
       <!--[] (Collège Louis-le-Grand) ; XVIIIe s. ; I : VI : 8e ; FRAN/MM//392 | Archives du Royaume Sect. Hist. ([]) ; [] ; [] ; [] -->
       <!-- Insitution comme écrite sur le document (Institution dans sa forme actuelle si elle existe) ; Date ; Cote ancienne ; Inventaire où se trouve cette cote -->
       
       <xsl:variable name="organisme-conservation">
           <conservateurs>
                <xsl:for-each select="$fichiersDept/documents/document/Historique_de_la_conservation[normalize-space(.)!='']">
                    <xsl:variable name="document" select="parent::document"/>
                    <xsl:variable name="notice" select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                    
                    <xsl:for-each select="tokenize(.,'\|')">
                        <xsl:analyze-string select="replace(.,'--',';')" regex="([^;]+);([^;]+);([^;]+);([^;]+)">
                            <xsl:matching-substring>
                                
                                <xsl:variable name="lieuConservation" select="
                                    if(not(contains(regex-group(1),'([])'))) 
                                    then(substring-before(substring-after(regex-group(1),'('),')')) 
                                    else(substring-before(regex-group(1),'(')) "/>
                                <xsl:if test="normalize-space($lieuConservation) !='[]'">
                                    <conservateur>
                                        <nom><xsl:value-of select="normalize-space($lieuConservation)"/></nom>
                                        <notice><xsl:value-of select="normalize-space($notice)"/></notice>
                                    </conservateur>
                                </xsl:if>
                            </xsl:matching-substring>
                        </xsl:analyze-string>
                    </xsl:for-each>
                </xsl:for-each>
           </conservateurs>
       </xsl:variable>
       
       <xsl:result-document href="../xml-temp/organisme-conservation.xml" method="xml" indent="yes" encoding="utf-8">
           <xsl:copy-of select="$organisme-conservation"/>
       </xsl:result-document>
       
       <xsl:variable name="organisme-conservation-dedoublonne">
           <conservateurs>
               <xsl:for-each-group select="$organisme-conservation/conservateurs/conservateur" group-by="nom">
                   <conservateur>
                       <nom><xsl:value-of select="current-grouping-key()"/></nom>
                       <xsl:for-each select="current-group()/notice">
                           <xsl:copy-of select="."/>
                       </xsl:for-each>
                   </conservateur>
               </xsl:for-each-group>
           </conservateurs>
       </xsl:variable>
       
       <xsl:result-document href="../output-rdf/organisme-conservation-all.rdf" method="xml" indent="yes" encoding="utf-8">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               
               <xsl:for-each select="$organisme-conservation-dedoublonne/conservateurs/conservateur">
                   <xsl:sort select="./nom"/>
                   <rico:CorporateBody rdf:about="corporateBody/{encode-for-uri(nom)}">
                       <rdfs:label xml:lang="fr"><xsl:value-of select="nom"/></rdfs:label>
                       <rico:name xml:lang="fr"><xsl:value-of select="nom"/></rico:name>
                       <xsl:for-each select="notice">
                           <oresm-onto:aConserve rdf:resource="instantiation/{encode-for-uri(concat('or-',normalize-space(.)))}"></oresm-onto:aConserve>
                       </xsl:for-each>
                   </rico:CorporateBody>
               </xsl:for-each>
               
               
               <!-- Ici les lieux de conservations atuels des archies dépouillées -->
               <!-- Une relation d'équivalence a été fait avec les entités IDREF et France Archives -->
               <rico:CorporateBody rdf:about="corporateBody/005061">
                   <rdfs:label xml:lang="fr">Archives nationales</rdfs:label>
                   <rico:name xml:lang="fr">Archives nationales</rico:name>
                   <owl:sameAs rdf:resource="http://data.archives-nationales.culture.gouv.fr/corporateBody/005061"/>
                   <owl:sameAs rdf:resourece="http://www.idref.fr/026359421/id"/>
               </rico:CorporateBody>
               
               <rico:CorporateBody rdf:about="corporateBody/050960067">
                   <rdfs:label xml:lang="fr">Bibliothèque interuniversitaire de la Sorbonne</rdfs:label>
                   <rico:name xml:lang="fr">Bibliothèque interuniversitaire de la Sorbonne</rico:name>
                   <owl:sameAs rdf:resource="http://www.idref.fr/050960067/id"/>
               </rico:CorporateBody>
               
               <rico:CorporateBody rdf:about="corporateBody/028173465">
                   <rdfs:label xml:lang="fr">Archives départementales de l'Oise</rdfs:label>
                   <rico:name xml:lang="fr">Archives départementales de l'Oise</rico:name>
                   <owl:sameAs rdf:resource="https://francearchives.gouv.fr/fr/service/33951"/>
                   <owl:sameAs rdf:resource="http://www.idref.fr/028173465/id"/>
               </rico:CorporateBody>
               
               <rico:CorporateBody rdf:about="corporateBody/029050421">
                   <rdfs:label xml:lang="fr">Archives départementales de la Seine-et-Marne</rdfs:label>
                   <rico:name xml:lang="fr">Archives départementales de la Seine-et-Marne</rico:name>
                   <owl:sameAs rdf:resource="https://francearchives.gouv.fr/fr/service/34157"/>
                   <owl:sameAs rdf:resource="http://www.idref.fr/029050421/id"/>
               </rico:CorporateBody>
               
           </rdf:RDF>
       </xsl:result-document>

        
        <!--<Lieu_Acte_insere>Parlement de Paris ; Palais de la Cité (Paris) ; [] ; https://fr.wikipedia.org/wiki/Parlement_de_Paris | Parlement de Paris ; Palais de la Cité (Paris) ; [] ; https://fr.wikipedia.org/wiki/Parlement_de_Paris</Lieu_Acte_insere>-->
        
        <!-- date de lieu ; lieu [forme actuelle normalisée] (ville ou pays) ; remarques sur l’histoire de l’évolution de la toponymie ; source de l’information | (répéter autant de fois que nécessaire)-->
        <!-- date de lieu ; lieu [forme actuelle normalisée] (ville ou pays) ; remarques sur l’histoire de l’évolution de la toponymie ; source de l’information | (répéter autant de fois que nécessaire)-->
        <!--  <Date_lieu_Acte_vidime>Viterbe ; Viterbe (Italie) ; [] ; https://fr.wikipedia.org/wiki/Viterbe</Date_lieu_Acte_vidime>-->
       
       <xsl:variable name="lieuVidime">
           <xsl:for-each select="$fichiersDept/documents/document/Acte_original_lieu_de_passage[normalize-space(.) != '']">
               
               <xsl:variable name="document" select="parent::document"/>

               <xsl:for-each select="tokenize(.,'\|')">
                   <xsl:variable name="position" select="position()"/>
                   <xsl:variable name="cote_original" select="normalize-space(tokenize($document/Acte_original_cote_actuelle,'\|')[position() = $position])"/>
                   <xsl:variable name="analyseOriginale" select="normalize-space(tokenize($document/Acte_original_analyse,'\|')[position() = $position])"/>
                   <xsl:variable name="dateOriginale" select="normalize-space(tokenize($document/Acte_original_date__forme_normalisée_,'\|')[position() = $position])"/>
                   <!-- on fait un lien uniquement si l'acte n'est pas traité ultérieurement, sinon on aurait une répétition-->
                   
                   <xsl:if test="not($fichiersDept/documents/document/Cote_actuelle[normalize-space(.) = $cote_original])
                       and count($document/preceding-sibling::document[Acte_original_cote_actuelle[count(tokenize(.,'\|')[normalize-space(.) = $cote_original and normalize-space(.) != '' and normalize-space(.) != '[]']) > 0]]) = 0
                       and count($document/preceding-sibling::document[Acte_original_analyse[count(tokenize(.,'\|')[normalize-space(.)=$analyseOriginale]) > 0] 
                       and Acte_original_date__forme_normalisée_[count(tokenize(.,'\|')[normalize-space(.)=$dateOriginale and normalize-space(.) != '' and normalize-space(.) != '[]']) > 0]]) = 0">
                       
                        <xsl:if test="normalize-space(.) != '[]'">
                            <lieu>
                                <!--<nom><xsl:value-of select="normalize-space(if(contains(.,';')) then(substring-before(.,';')) else(.))"/></nom>-->
                                <xsl:variable name="liste" select="tokenize(.,';')"/>
                                <nom><xsl:value-of select="replace(normalize-space($liste[1]),' +$| +$','')"/></nom>
                                <xsl:if test="matches(.,';')">
                                    <nom_normalise><xsl:value-of select="substring-before(replace(normalize-space($liste[2]),' +$| +$',''),' (')"/></nom_normalise>
                                    <remarques><xsl:value-of select="replace(normalize-space($liste[3]),' +$| +$','')"/></remarques>
                                    <note><xsl:value-of select="replace(normalize-space($liste[4]),' +$| +$','')"/></note>
                                </xsl:if>
                                <notice><xsl:value-of select="concat('or-',$document/ancestor::documents/@id,'-',count($document/preceding-sibling::document)+1,'-virt',$position)"/></notice>
                            </lieu>
                        </xsl:if>
                   </xsl:if>
               </xsl:for-each>
           </xsl:for-each>
       
           <xsl:for-each select="$fichiersDept/documents/document/Acte_inséré_lieu_de_passage[normalize-space(.) != '']">
               <xsl:variable name="document" select="parent::document"/>
               <xsl:for-each select="tokenize(.,'\|')">
                   <xsl:variable name="position" select="position()"/>
                   <xsl:if test="normalize-space(.) != '[] ; [] ; [] ; []'">
                        <!-- on fait un lien uniquement si l'acte n'est pas traité ultérieurement, sinon on aurait une répétition-->
                        <xsl:if test="not($fichiersDept/documents/document/Cote_actuelle[normalize-space(.) = normalize-space(tokenize($document/Acte_inséré_cote_actuelle,'\|')[position() = $position])])">
                            
                            <lieu>
                                <!--<nom><xsl:value-of select="normalize-space(if(contains(.,';')) then(substring-before(.,';')) else(.))"/></nom>-->
                                <xsl:variable name="liste" select="tokenize(.,';')"/>
                                <nom><xsl:value-of select="replace(normalize-space($liste[1]),' +$| +$','')"/></nom>
                                <xsl:if test="matches(.,';')">
                                    <nom_normalise><xsl:value-of select="replace(normalize-space($liste[2]),' +$| +$','')"/></nom_normalise>
                                    <remarques><xsl:value-of select="replace(normalize-space($liste[3]),' +$| +$','')"/></remarques>
                                    <note><xsl:value-of select="replace(normalize-space($liste[4]),' +$| +$','')"/></note>
                                </xsl:if>
                                <notice><xsl:value-of select="concat('or-',$document/ancestor::documents/@id,'-',count($document/preceding-sibling::document)+1,'-ins',$position)"/></notice>
                            </lieu>
                        </xsl:if>
                   </xsl:if>
               </xsl:for-each>
                   
           </xsl:for-each>
       </xsl:variable>
       <xsl:result-document href="../xml-temp/lieux-vidimes-inseres.xml" method="xml" encoding="utf-8" indent="yes">
           <xsl:copy-of select="$lieuVidime"></xsl:copy-of>
       </xsl:result-document>
       <xsl:variable name="lieuVidimeDedoublonne">
           <xsl:for-each-group select="$lieuVidime/lieu" group-by="./nom">
               <lieu>
                   <nom><xsl:value-of select="current-grouping-key()"/></nom>
                   <xsl:copy-of select="current-group()[./nom_normalise][1]/nom_normalise"></xsl:copy-of>
                   <xsl:copy-of select="current-group()[./remarques][1]/remarques"></xsl:copy-of>
                   <xsl:copy-of select="current-group()[./note][1]/note"></xsl:copy-of>
                   <xsl:for-each select="current-group()">
                       
                       <xsl:copy-of select="./notice"></xsl:copy-of>
                   </xsl:for-each>
               </lieu>
           </xsl:for-each-group>
       </xsl:variable>
       <xsl:result-document href="../xml-temp/lieux-vidimes-inseres-dedoublons.xml" method="xml" encoding="utf-8" indent="yes">
           <xsl:copy-of select="$lieuVidimeDedoublonne"></xsl:copy-of>
       </xsl:result-document>
       
       <xsl:result-document href="../temp-rdf/lieux-actes-vidimes-inseres.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
                
                
                <xsl:for-each select="$lieuVidimeDedoublonne/lieu">
                    <xsl:sort select="./nom" order="ascending" data-type="text"/>
                    <xsl:variable name="nom" select='if(./nom_normalise) then(./nom_normalise) else(./nom)'/>
                    <rico:Place rdf:about="{concat('place/',encode-for-uri($nom))}">
                        <rdfs:label xml:lang="fr"><xsl:value-of select="$nom"/></rdfs:label>
                        <rico:name xml:lang="fr"><xsl:value-of select="$nom"/></rico:name>
                        <xsl:if test="./note and ./note!='[]'">
                            <rdfs:seeAlso><xsl:value-of select="./note"/></rdfs:seeAlso>
                        </xsl:if>
                        <xsl:if test="./remarques and ./remarques!='[]'">
                            <rico:descriptiveNote><xsl:value-of select="./remarques"/></rico:descriptiveNote>
                        </xsl:if>
                        <xsl:for-each select="./notice">
                            <oresm-onto:estLieudePassageActe rdf:resource="{concat('recordResource/',replace(.,' ',''))}"/>
                        </xsl:for-each>
                    </rico:Place>
                </xsl:for-each>
                
            </rdf:RDF>
       </xsl:result-document>
       
       <!-- GROUPE LES PLACES PAR rdfs:about -->
       <!-- //rico:Place[./oresm-onto:estLieudePassageActe/following-sibling::rico:isPlaceAssociatedWith] -->
       
       <xsl:variable name="placeGroupe" select="collection(concat('../temp-rdf/','?select=lieux-*.rdf'))/rdf:RDF/rico:Place"/>
       
       <xsl:result-document href="../output-rdf/lieux.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               <xsl:for-each-group select="$placeGroupe" group-by="upper-case(./@rdf:about)">
                   <xsl:sort select="current-group()[1]/rdfs:label"/>
                   <rico:Place rdf:about="{encode-for-uri(current-group()[1]/rdfs:label)}">
                       <xsl:copy-of select="current-group()[1]/rdfs:label"/>
                        <xsl:copy-of select="current-group()[1]/rico:name"/>
                        <xsl:copy-of select="current-group()/rdfs:seeAlso"/>
                        <xsl:copy-of select="current-group()[rico:latitude][1]/rico:latitude"/>
                        <xsl:copy-of select="current-group()[rico:longitude][1]/rico:longitude"/>
                        <xsl:copy-of select="current-group()/oresm-onto:estLieudePassageActe"/>
                        <xsl:copy-of select="current-group()/rico:isPlaceAssociatedWith"/>
                   </rico:Place>
               </xsl:for-each-group>
               
           </rdf:RDF>
       </xsl:result-document>
       
       <!-- ### LES DATES ### -->
       <!-- les traiter comme des entités à part entière -->
       <!-- on a 4 champs : <Date__forme_littérale_>le mercredi huitme jour du mois de mars l'an mil CCCC soixante dix neuf</Date__forme_littérale_>
        <Date__forme_rédigée_> 8 mars 1480 </Date__forme_rédigée_>
        <Date__forme_normalisée_> 1480-03-08 </Date__forme_normalisée_>
         <Critique_de_la_date> date convertie en n. st. (8 mars 1479 a. st.).  </Critique_de_la_date>
       
       <Date__forme_normalisée_> 1530-01-01 / 1530-12-31 </Date__forme_normalisée_>
       -->
       <!-- on va utiliser rico:SingleDate et rico:dateRange; il faudra peut-être tout changer si on passe à RiC-O 1.0 
       rico:expressedDate pour la forme littérale
       rico:normalizedValue pour la forme rédigée
       rico:normalizedDateValue pour la forme normalisée
       rico:descriptiveNote pour la note sur la critique 
       Pour l'IRI on va encoder la forme litérale si elle est disponible
       -->
       
       <!-- on part de l'idée qu'il y a a priori une date normalisée -->
       <!-- FL changement en supposant qu'il y a une date rédigée plutôt, celle ci est systématique quand il y a une date -->
       
       <xsl:variable name="datesActes">
           <datesActes>
               <xsl:for-each select="$fichiersDept/documents/document/Date__forme_rédigée_[normalize-space(.)!=''] ">
                   <xsl:variable name="doc" select="normalize-space(parent::document/Identifiant_du_guide)"/>
                   <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                 
                   <xsl:variable name="notice"
                       select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                   <dateActe>
                       <formeRedigee><xsl:value-of select="normalize-space(.)"/></formeRedigee>
                       <xsl:if test="normalize-space(parent::document/Date__forme_littérale_)!=''">
                           <formeLitterale><xsl:value-of select="normalize-space(replace(replace(parent::document/Date__forme_littérale_, $apos, '’'),'\|',';'))"/></formeLitterale>
                       </xsl:if>
                       
                       <!-- Traitement de normalisation de la date rédigée quand on peut -->
                       <xsl:choose>
                           
                           <!-- Il y a une forme normalisée -->
                           <xsl:when test="normalize-space(parent::document/Date__forme_normalisée_)!=''">
                               <standardDate><xsl:value-of select="normalize-space(replace(parent::document/Date__forme_normalisée_, $apos, '’'))"/></standardDate>
                           </xsl:when>
                           
                           <!-- La forme rédigée est de la forme dd {mois en lettre} aaaa -->
                           <xsl:when test="matches(normalize-space(.),'^[0-9]{1,2} [^ ]+ [0-9]{4}$')">
                               <xsl:analyze-string select="normalize-space(.)" regex="^([0-9]{{1,2}}) ([^ ]+) ([0-9]{{4}})$">
                                   <xsl:matching-substring>
                                       <xsl:variable name="jour" select="if(string-length(regex-group(1))=1) then(concat('0',regex-group(1))) else(regex-group(1))"/>
                                       <xsl:variable name="mois"><xsl:call-template name="mois_en_nombre"><xsl:with-param name="redige" select="regex-group(2)"/></xsl:call-template></xsl:variable>
                                       <xsl:variable name="annee" select="regex-group(3)"/>
                                       <standardDate><xsl:value-of select="concat($annee,'-',$mois,'-',$jour)"/></standardDate>
                                   </xsl:matching-substring>
                               </xsl:analyze-string>
                           </xsl:when>
                           
                           <!-- La forme rédigée est une année en chiffres-->
                           <xsl:when test="matches(normalize-space(.),'^[0-9]{4}$')">
                               <standardDate><xsl:value-of select="normalize-space(.)"/>-01-01/<xsl:value-of select="normalize-space(.)"/>-12-31</standardDate>
                           </xsl:when>
                           
                           <!-- La forme rédigée est composée de deux années en chiffres séparés par un '-' -->
                           <xsl:when test="matches(normalize-space(.),'^[0-9]{4}-[0-9]{4}$')">
                               <standardDate><xsl:value-of select="substring-before(normalize-space(.),'-')"/>-01-01/<xsl:value-of select="substring-after(normalize-space(.),'-')"/>-12-31</standardDate>
                           </xsl:when>
                           
                           <!-- La forme rédigée est un unique siècle en chiffre romain-->
                           <xsl:when test="matches(normalize-space(.),'^XVI{0,3}[^-]+$')">
                               <xsl:variable name="siecle"><xsl:call-template name="romain"><xsl:with-param name="romain" select="substring-before(normalize-space(.),'e ')"/></xsl:call-template></xsl:variable>
                               <standardDate><xsl:value-of select="xs:integer($siecle)-1"/>01-01-01/<xsl:value-of select="$siecle"/>00-12-31</standardDate>
                           </xsl:when>
                           
                           <!-- La forme rédigée est un mois en lettre suivi d'une année-->
                           <xsl:when test="matches(normalize-space(.),'^[^è -]+ [0-9]{4}$')">
                               <xsl:variable name="mois"><xsl:call-template name="mois_en_nombre"><xsl:with-param name="redige" select="substring-before(normalize-space(.),' ')"/></xsl:call-template></xsl:variable>
                               <xsl:variable name="normalise">
                                   <xsl:value-of select="substring-after(normalize-space(.),' ')"/>-
                                   <xsl:value-of select="$mois"/>-01/
                                   <xsl:value-of select="substring-after(normalize-space(.),' ')"/>-
                                   <xsl:value-of select="$mois"/>-
                                   <xsl:value-of select="if(matches($mois,'01|03|05|07|08|10|12')) then('31') else(if($mois='02') then('28') else('30'))"/>
                               </xsl:variable>
                               <standardDate><xsl:value-of select="replace($normalise,' |\n','')"/></standardDate>
                           </xsl:when>
                       
                       </xsl:choose>
                       <xsl:if test="normalize-space(parent::document/Critique_de_la_date)!=''">
                           <xsl:for-each select="tokenize(parent::document/Critique_de_la_date,'\|')[not(contains(.,'original'))]">
                               <note><xsl:value-of select="normalize-space(replace(., $apos, '’'))"/></note>
                           </xsl:for-each>
                       </xsl:if>
                       <infos>
                           <xsl:value-of select="$doc"/>
                           <xsl:text> [cote </xsl:text>
                           <xsl:value-of select="$cote"/>
                           <xsl:text>] (notice </xsl:text>
                           <xsl:value-of select="$notice"/>
                           <xsl:text>)</xsl:text>
                       </infos>
                   </dateActe>
               </xsl:for-each>
               <xsl:for-each select="$fichiersDept/documents/document/Acte_inséré_date__forme_normalisée_[normalize-space(.) != '']">
                   <xsl:variable name="doc" select="normalize-space(parent::document/Identifiant_du_guide)"/>
                   <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                   <xsl:variable name="notice" select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                   <xsl:for-each select="tokenize(.,'\|')">
                       <xsl:variable name="position" select="position()"/>
                       <dateActe>
                           <standardDate><xsl:value-of select="normalize-space(.)"/></standardDate>
                           <infos><xsl:value-of select="$doc"/>
                               <xsl:text> [cote </xsl:text>
                               <xsl:value-of select="$cote"/>
                               <xsl:text>] (notice </xsl:text>
                               <xsl:value-of select="concat($notice,'-ins',$position)"/>
                               <xsl:text>)</xsl:text></infos>
                       </dateActe>
                   </xsl:for-each>
               </xsl:for-each>
               
               <xsl:for-each select="$fichiersDept/documents/document/Acte_original_date__forme_normalisée_[normalize-space(.)!='']">
                   <xsl:variable name="doc" select="normalize-space(parent::document/Identifiant_du_guide)"/>
                   <xsl:variable name="document" select="parent::document"/>
                   <xsl:variable name="cote" select="normalize-space(parent::document/Cote_actuelle)"/>
                   <xsl:variable name="notice" select="concat(ancestor::documents/@id, '-', count(parent::document//preceding-sibling::document) + 1)"/>
                   
                   <xsl:for-each select="tokenize(.,'\|')">
                       <xsl:variable name="position" select="position()"/>
                       <xsl:variable name="cote_original" select="normalize-space(tokenize($document/Acte_original_cote_actuelle,'\|')[position() = $position])"/>
                       <xsl:variable name="analyseOriginale" select="normalize-space(tokenize($document/Acte_original_analyse,'\|')[position() = $position])"/>
                       <xsl:variable name="dateOriginale" select="normalize-space(.)"/>
                       
                       <!-- On vérifie si l'acte original n'a pas déjà été traité avant, pour éviter de faire un doublon 
                            Voir explications à Traitement actes originaux
                       -->
                       
                       <xsl:if test="$dateOriginale != '[]' and not($fichiersDept/documents/document/Cote_actuelle[normalize-space(.) = $cote_original])
                           and count($document/preceding-sibling::document[Acte_original_cote_actuelle[count(tokenize(.,'\|')[normalize-space(.) = $cote_original and normalize-space(.) != '[]' and normalize-space(.) != '']) > 0]]) = 0
                           and count($document/preceding-sibling::document[Acte_original_analyse[count(tokenize(.,'\|')[normalize-space(.)=$analyseOriginale and normalize-space(.) != '']) > 0] and Acte_original_date__forme_normalisée_[count(tokenize(.,'\|')[normalize-space(.)=$dateOriginale]) > 0]]) = 0 ">
                            <dateActe>
                                <standardDate><xsl:value-of select="normalize-space(.)"/></standardDate>
                                <xsl:if test="normalize-space($document/Critique_de_la_date)!=''">
                                    <xsl:for-each select="tokenize($document/Critique_de_la_date,'\|')[contains(.,'original')]">
                                        <note><xsl:value-of select="normalize-space(replace(., $apos, '’'))"/></note>
                                    </xsl:for-each>
                                </xsl:if>
                                <infos><xsl:value-of select="$doc"/>
                                    <xsl:text> [cote </xsl:text>
                                    <xsl:value-of select="$cote"/>
                                    <xsl:text>] (notice </xsl:text>
                                    <xsl:value-of select="concat($notice,'-virt',$position)"/>
                                    <xsl:text>)</xsl:text></infos>
                            </dateActe>
                       </xsl:if>
                   </xsl:for-each>
               </xsl:for-each>
           </datesActes>
           
       </xsl:variable>
       <xsl:result-document href="../xml-temp/datesActes.xml"  method="xml" encoding="utf-8" indent="yes">
           <xsl:copy-of select="$datesActes"></xsl:copy-of>
       </xsl:result-document>
       <xsl:result-document href="../output-rdf/datesActes-all.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               <!-- pour l'instant on considère que la date est vraiment associée au document et on groupe en utilisant en premier lieu la forme littérale ; c'est aussi cette forme qui sert à produire un IRI--> 
               <xsl:for-each-group select="$datesActes/datesActes/dateActe" group-by="concat(formeLitterale, ':', formeRedigee, ' | ', replace(standardDate,' / ','/'))">
                   <xsl:variable name="date" select="current-grouping-key()"/>
                   
                   <!-- Si pas de valeur littérale alors on prend la valeur rédigée si pas de valeur rédigée alors on prend la valeur normalisée-->
                   <xsl:variable name="valeur" select="
                       if (substring-before($date,':')!='') 
                       then(substring-before($date,':'))
                       else( 
                       if(substring-before(substring-after($date,':'),' |') !='')
                       then(substring-before(substring-after($date,':'),' |'))
                       else(normalize-space(substring-after($date, '| ')))
                       )"/>
                   
                   <xsl:element name="{if(contains(substring-after($date, '|'),'/')) then('rico:DateRange') else('rico:SingleDate')}">
                       <xsl:attribute name="rdf:about" select="concat('date/',encode-for-uri($valeur))"/>
                       <!-- FLORIAN DONE ifférencier les DateSingle et DateRange (ce sont des sous-classes de Date dans RiC-O-->
                       <!-- FLORIAN DOING typer les dates normalisées en utilisant les datatypes W3C ; il est aussi possible d'ajouter une datatype property rico:dateStandard pour indiquer qu'on utilise ISO 8601 -->  
                       
                       <rdfs:label xml:lang="fr"><xsl:value-of select="normalize-space($valeur)"/></rdfs:label>
                       <rico:name xml:lang="fr"><xsl:value-of select="normalize-space($valeur)"/></rico:name>
                       <xsl:if test="(contains(substring-after($date, '|'),'/'))">
                            <rico:hasBeginningDate rdf:resource="date/{encode-for-uri(normalize-space(tokenize(substring-after($date, '|'),'/')[1]))}"></rico:hasBeginningDate>
                            <rico:hasEndDate rdf:resource="date/{encode-for-uri(normalize-space(tokenize(substring-after($date, '|'),'/')[2]))}"></rico:hasEndDate>
                       </xsl:if>
                       <xsl:if test="normalize-space(substring-after($date, '| ')) != ''">
                            <rico:normalizedDateValue rdf:datatype="http://www.w3.org/2001/XMLSchema#date">
                             <xsl:value-of select="normalize-space(substring-after($date, '| '))"/>
                            </rico:normalizedDateValue>
                       </xsl:if>
                       <xsl:if test="normalize-space(substring-before($date, ':'))!=''">
                            <oresm-onto:formeLitteraleDate><xsl:value-of select="normalize-space(substring-before($date, ':'))"/></oresm-onto:formeLitteraleDate>
                       </xsl:if>
                       <xsl:if test="normalize-space(substring-after(substring-before($date, '|'),':'))!=''">
                           <oresm-onto:formeFrancaiseRedigeeDate xml:lang="fr"><xsl:value-of select="normalize-space(substring-before(substring-after($date, ':'), ' |'))"/></oresm-onto:formeFrancaiseRedigeeDate>
                       </xsl:if>
                       
                       <xsl:for-each-group select="current-group()" group-by="
                            if (note!='')
                            then (note)
                            else ('rien')">
                            <xsl:if test="current-grouping-key()!='rien'">
                                <xsl:for-each select="tokenize(current-grouping-key(),'\|')">
                                    <oresm-onto:critiqueDate xml:lang="fr"><xsl:value-of select="normalize-space(.)"/></oresm-onto:critiqueDate>
                                </xsl:for-each>
                            </xsl:if>
                           <!-- TODO FLORIAN : la rechecrhe XPath //rico:Date[count(rico:descriptiveNote)&gt;1] sur les résultats retourne 2 cas très bizarres (voir les données source, c'est là que ça doit clocher) ; par ailleurs il semble que le champ forme littérale contient parfois plusieurs dates séparées par  un |... -->
                           <!-- Les deux descriptives notes font références à la date de l'acte original est pas à l'acte vidimé -->
                           
                           <xsl:for-each select="current-group()">
                           <xsl:variable name="ORESMDocId">    
                                <xsl:value-of select="concat('or-', substring-before(substring-after(infos, 'notice '), ')'))"/>
                           </xsl:variable>
                                <oresm-onto:estDateDeCreationDe rdf:resource="recordResource/{$ORESMDocId}"/>
                           </xsl:for-each>
                       </xsl:for-each-group>
                       
                   </xsl:element>
                   <xsl:if test="contains(substring-after($date, '|'),'/')">
                       <xsl:for-each select="tokenize(substring-after($date, '|'),'/')">
                           <rico:SingleDate rdf:about="date/{encode-for-uri(normalize-space(.))}">
                               <rdfs:label xml:lang="fr"><xsl:value-of select="."/></rdfs:label>
                               <rico:name xml:lang="fr"><xsl:value-of select="."/></rico:name>
                               <rico:normalizedDateValue rdf:datatype="http://www.w3.org/2001/XMLSchema#date"><xsl:value-of select="normalize-space(.)"/></rico:normalizedDateValue>
                           </rico:SingleDate>
                       </xsl:for-each>     
                   </xsl:if>
               </xsl:for-each-group>
               
           </rdf:RDF>
       </xsl:result-document>
       
       

       
       <!-- Champs bibliographie et editions traités dans les mêmes fichiers de sortie -->
       
       <xsl:variable name="bibliographie">
           <bibliographies>
               <xsl:for-each select="$fichiersDept/documents/document/Bibliographie[normalize-space(.)!='']">
                   <xsl:variable name="position" select="count(parent::document/preceding-sibling::document) + 1"/>
                   <xsl:variable name="notice" select="concat(ancestor::documents/@id,'-',$position)"/>
                   <xsl:for-each select="tokenize(.,'\|')">
                       <bibliographie>
                           <valeur><xsl:value-of select="normalize-space(substring-after(.,', '))"/></valeur>
                           <auteur><xsl:value-of select="normalize-space(substring-before(.,','))"/></auteur>
                           <notice><xsl:value-of select="$notice"/></notice>
                       </bibliographie>
                   </xsl:for-each>
               </xsl:for-each>
               <xsl:for-each select="$fichiersDept/documents/document/Éditions[normalize-space(.)!='']">
                   <xsl:variable name="position" select="count(parent::document/preceding-sibling::document) + 1"/>
                   <xsl:variable name="notice" select="concat(ancestor::documents/@id,'-',$position)"/>
                   <xsl:for-each select="tokenize(.,'\|')">
                       <xsl:variable name="titre">
                           <xsl:choose>
                               <!-- On développe les titres abrégés -->
                               <!-- Charles Jourdain, Index chronologicus chartarum pertinentium ad historiam universitatis Parisiensis, Paris, Hachette, 1862, n° 1104
                               Du Boulay, Historia universitatis Parisiensis, III, p. 383 
                               H. Denifle et E. Chatelain, Chartularium Universitatis Parisiensis..., Paris, Delalain, I, 1889, n° 413 -->
                               <xsl:when test="contains(.,'Cart. ')">
                                   <xsl:value-of select="concat('H. Denifle et E. Chatelain, Chartularium Universitatis Parisiensis..., Paris, Delalain, I, 1889, n° ',substring-after(.,'Cart. '))"/>
                               </xsl:when>
                               <xsl:when test="contains(.,', Index,')">
                                   Charles Jourdain, Index chronologicus chartarum pertinentium ad historiam universitatis Parisiensis, Paris, Hachette, 1862, n°<xsl:call-template name="romain"><xsl:with-param name="romain" select="substring-after(.,'n°')"></xsl:with-param></xsl:call-template>
                               </xsl:when>
                               <xsl:when test="contains(.,'Du Boulay, tome')">
                                   <xsl:value-of select="replace(.,'tome','Historia universitatis Parisiensis,')"></xsl:value-of>
                               </xsl:when>
                               <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
                           </xsl:choose>
                       </xsl:variable>
                       <bibliographie>
                           <valeur><xsl:value-of select="if (contains($titre,',')) then(normalize-space(substring-after($titre,', '))) else($titre)"/></valeur>
                           <auteur><xsl:value-of select="if (contains($titre,',')) then(normalize-space(substring-before($titre,','))) else()"/></auteur>
                           <edite><xsl:value-of select="$notice"/></edite>
                       </bibliographie>
                   </xsl:for-each>
               </xsl:for-each>
           </bibliographies>
       </xsl:variable>
       
       <xsl:result-document href="../xml-temp/bibliographie.xml" method="xml" encoding="utf-8" indent="yes">
           <xsl:copy-of select="$bibliographie"></xsl:copy-of>
       </xsl:result-document>
       
       <xsl:result-document href="../output-rdf/bibliographie.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               <xsl:for-each-group select="$bibliographie/bibliographies/bibliographie" group-by="valeur[normalize-space(.)!='']">
                   <rico:RecordResource rdf:about="recordResource/{encode-for-uri(current-grouping-key())}">
                       <rdfs:label xml:lang="fr"><xsl:value-of select="current-grouping-key()"/></rdfs:label>
                       <rico:title xml:lang="fr"><xsl:value-of select="current-grouping-key()"/></rico:title>
                       <xsl:for-each select="current-group()/notice">
                           <rico:hasOrHadSubject rdf:resource="recordResource/or-{encode-for-uri(.)}"></rico:hasOrHadSubject>
                       </xsl:for-each>
                       <xsl:for-each select="current-group()/edite">
                           <oresm-onto:inclutEditionDe rdf:resource="recordResource/or-{encode-for-uri(.)}"></oresm-onto:inclutEditionDe>
                       </xsl:for-each>
                   </rico:RecordResource>
               </xsl:for-each-group>
           </rdf:RDF>
       </xsl:result-document>
       
       <xsl:result-document href="../output-rdf/auteurs.rdf" method="xml" encoding="utf-8" indent="yes">
           <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
               xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
               xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
               xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
               xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
               <xsl:for-each-group select="$bibliographie/bibliographies/bibliographie" group-by="auteur[normalize-space(.)!='']">
                   <rico:Person rdf:about="person/{encode-for-uri(current-grouping-key())}">
                       <rdfs:label xml:lang="fr"><xsl:value-of select="current-grouping-key()"/></rdfs:label>
                       <rico:name xml:lang="fr"><xsl:value-of select="current-grouping-key()"/></rico:name>
                       <xsl:for-each-group select="current-group()" group-by="valeur">
                           <rico:isAuthorOf rdf:resource="recordResource/{encode-for-uri(current-grouping-key())}"></rico:isAuthorOf>
                       </xsl:for-each-group>
                   </rico:Person>
               </xsl:for-each-group>
           </rdf:RDF>
       </xsl:result-document>
       
       <!-- ### LES DOCUMENTS MAINTENANT, AINSI QUE LEURS INSTANTIATIONS ET LES ACTES VIDIMES/RECOPIES ### -->
       <!-- cette fois-ci il va y avoir un fichier XML/RDF par document décrit -->
       <xsl:for-each select="$fichiersDept/documents/document">
            <xsl:variable name="id" select="count(preceding-sibling::document)+1"/>
           <xsl:variable name="cote" select="normalize-space(Cote_actuelle)"/>
           <xsl:variable name="coll" select="parent::documents/@id"/>
         
           <xsl:variable name="idEAD" select="normalize-space(replace(Identifiant_du_guide, '—', '--'))"/>
       
           <!-- lieu de conservation actuel : voir le traitement des cotes actuelles : il vaut mieux se fier à la cote indiquée -->
           <xsl:variable name="lieuConservation">
               <xsl:choose>
                   <xsl:when test="starts-with($cote, 'FRAN')">
                       <xsl:text>FRAN</xsl:text>
                   </xsl:when>
                   <xsl:when test="starts-with($cote, 'FRAD077')">
                       <xsl:text>FRAD077</xsl:text>
                   </xsl:when>
                   <xsl:when test="starts-with($cote, 'FRAD060')">
                       <xsl:text>FRAD060</xsl:text>
                   </xsl:when>
                   <xsl:when test="starts-with($cote, 'Bibliothèque')">
                       <xsl:text>BIS</xsl:text>
                   </xsl:when>
                   
               </xsl:choose>
           </xsl:variable>
           
            <xsl:result-document href="../output-rdf/document-{$coll}-{$id}.rdf"  method="xml" encoding="utf-8" indent="yes">
                <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                    xmlns:rico="https://www.ica.org/standards/RiC/ontology#"
                    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/1999/xhtml"
                    xmlns:dc="http://purl.org/dc/elements/1.1/" xml:base="http://data.oresm.fr/">
                   
                    <rico:RecordResource>
                        <xsl:attribute name="rdf:about" select="concat('recordResource/or-', $coll, '-', $id)"/>
                         <rico:title xml:lang="fr">
                             <xsl:value-of select="normalize-space(Intitulé)"/>
                         </rico:title>
                        <rdfs:label xml:lang="fr"><xsl:value-of select="normalize-space(Intitulé)"/></rdfs:label>
                        <xsl:choose>
                            <!--DONE FLORIAN voir si on peut gérer aussi le cas des documents pour lesquels on a un id Calames -->
                       
                            <xsl:when test="starts-with($cote, 'FRAN')">
                                <rdfs:seeAlso>
                                    <xsl:attribute name="rdf:resource">
                                        <!-- https://www.siv.archives-nationales.culture.gouv.fr/siv/UD/FRAN_IR_042112/c1p6zoewyiib-1dffov155uu7v-->
                                        <xsl:value-of select="concat('https://www.siv.archives-nationales.culture.gouv.fr/siv/UD/FRAN_IR_032408/', $idEAD)"/>
                                    </xsl:attribute>
                                </rdfs:seeAlso>
                            </xsl:when>
                            
                            <xsl:when test="starts-with($cote, 'Bibliothèque de la Sorbonne')">
                                <rdfs:seeAlso>
                                    <xsl:attribute name="rdf:resource">
                                        <!-- www.calames.abes.fr/pub/#details?id=Calames-201311161611269092-->
                                        <xsl:value-of select="concat('https://www.calames.abes.fr/pub/#details?id=', $idEAD)"/>
                                    </xsl:attribute>
                                </rdfs:seeAlso>
                            </xsl:when>
                            
                        </xsl:choose>
                        
                        <xsl:if test="normalize-space(Langue_des_documents)!=''">
                            <xsl:for-each select="tokenize(normalize-space(Langue_des_documents), '\|')[normalize-space(.)!='']">
                                <xsl:choose>
                                    
                                    <xsl:when test="matches(.,'fr','i')">
                                        <rico:hasOrHadLanguage rdf:resource="http://data.archives-nationales.culture.gouv.fr/language/FRAN_RI_100-name4"/>
                                    </xsl:when>
                                    <xsl:when test="matches(.,'lat','i')">
                                        <!-- nota cela n'est correct que si on a affaire à un Record ou un Record Part -->
                                        <rico:hasOrHadLanguage rdf:resource="http://data.archives-nationales.culture.gouv.fr/language/FRAN_RI_100-name9"/>
                                    </xsl:when>
                                    <!-- collection('../src-xml/depouillements')/documents/document/Langue_des_documents[not(matches(.,'fr|lat','i'))] -->
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:if>
                        
                        <xsl:if test="Nombre_approximatif_de_noms_présents_dans_le_document[normalize-space(.)!='']">
                            <oresm-onto:nombreApproximatifNomsPersonnesPresents rdf:datatype="http://www.w3.org/2001/XMLSchema#integer"><xsl:value-of select="normalize-space(Nombre_approximatif_de_noms_présents_dans_le_document)"/></oresm-onto:nombreApproximatifNomsPersonnesPresents>
                        </xsl:if>
                        
                        <xsl:if test="matches(Acte_inséré_analyse,'^[0-9]+$') or normalize-space(Nombres_d_actes_insérés) != ''">
                            <oresm-onto:nombreActesInseres><xsl:value-of select="Acte_inséré_analyse"/><xsl:value-of select="Nombres_d_actes_insérés"/></oresm-onto:nombreActesInseres>
                        </xsl:if>
                        
                        <xsl:if test="Autres_descriptions_physiques[normalize-space(.)!='']">
                            <xsl:for-each select="tokenize(Autres_descriptions_physiques,'\|')">
                                <xsl:if test="matches(normalize-space(.),'sceau|scellé|bulle','i')">
                                    <oresm-onto:presenceDeSceau rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean">true</oresm-onto:presenceDeSceau>
                                    <oresm-onto:noteSceau><xsl:value-of select="normalize-space(tokenize(.,'#')[not(contains(.,'[]'))])"/></oresm-onto:noteSceau>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:if>
                       
                        
                        <xsl:if test="Remarques[matches(.,'intitulés ont donc été forgés')]">
                            <oresm-onto:remarque xml:lang="fr"><xsl:value-of select="tokenize(Remarques,'\|')[matches(.,'intitulés ont donc été forgés')]"/></oresm-onto:remarque>
                        </xsl:if>
                        
                        
                        <!-- DONE -->
                        <xsl:if test="normalize-space(Sources_complémentaires)!=''">
                            <xsl:for-each select="tokenize(Sources_complémentaires,'\|')">
                                <xsl:variable name="cote_boucle" select="normalize-space(.)"/>
                                <xsl:variable name="piece" select="$fichiersDept/documents/document[starts-with(normalize-space(Cote_actuelle),$cote_boucle)]"/>
                                <xsl:choose>
                                    <xsl:when test="$piece">
                                        <xsl:for-each select="$piece">
                                            <xsl:variable name="notice" select="concat('or-',./ancestor::documents/@id,'-',count(./preceding-sibling::document)+1)"/>
                                            <rico:isRecordResourceAssociatedWithRecordResource rdf:resource="recordResource/{$notice}"></rico:isRecordResourceAssociatedWithRecordResource>
                                        </xsl:for-each>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <rico:isRecordResourceAssociatedWithRecordResource>
                                            <rico:RecordResource>
                                                <rico:identifier><xsl:value-of select="$cote_boucle"/></rico:identifier>
                                            </rico:RecordResource>
                                        </rico:isRecordResourceAssociatedWithRecordResource>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:if>
                      
                        <rico:hasInstantiation>
                            <xsl:attribute name="rdf:resource">
                                <xsl:value-of select="concat('instantiation/or-', $coll, '-', $id)"/>
                            </xsl:attribute>
                        </rico:hasInstantiation>
                        
                        
                        <!-- on traite les actes originaux déjà présent dans les dépouillements en retrouvant par la cote de l'acte qui est dans Acte_original_cote_actuelle -->
                        <!-- On ne fait pas la même chose pour les actes insérés car on la côte actuels d'aucun de ces actes et avec la nouvelle méthodolgie on ne l'aura pas-->
                        
                        
                        <xsl:if test="normalize-space(Acte_original_analyse)!=''">
                            <xsl:variable name="document" select="."/>
                            <xsl:variable name="type" select="Type_de_document"/>
                            <xsl:for-each select="tokenize(./Acte_original_analyse,'\|')">
                                <xsl:variable name="position" select="position()"/>
                                <xsl:variable name="analyseOriginale" select="normalize-space(.)"/>
                                <xsl:variable name="coteOriginale" select="normalize-space(tokenize($document/Acte_original_cote_actuelle,'\|')[position() = $position])"/>
                                <xsl:variable name="dateOriginale" select="normalize-space(tokenize($document/Acte_original_date__forme_normalisée_,'\|')[position() = $position])"/>
                                
                                <xsl:variable name="aRelierURI">
                                    <xsl:variable name="debutURI" select="'recordResource/or-'"/>
                                    <xsl:choose>
                                        <xsl:when test="$coteOriginale != '' and $coteOriginale != '[]'">
                                            <xsl:choose>
                                                <xsl:when test="count($fichiersDept/documents/document/Cote_actuelle[normalize-space(.) = $coteOriginale]) > 0">
                                                     <xsl:variable name="documentALier" select="$fichiersDept/documents/document[Cote_actuelle[normalize-space(.) = $coteOriginale]]"/>
                                                     <xsl:value-of select="concat($debutURI,$documentALier/parent::documents/@id,'-',count($documentALier/preceding-sibling::document)+1)"/>
                                                 </xsl:when>
                                                <xsl:when test="$document/preceding-sibling::document[Acte_original_cote_actuelle[count(tokenize(.,'\|')[normalize-space(.) = $coteOriginale])>0]]">
                                                    <xsl:variable name="documentALier" select="$document/preceding-sibling::document[Acte_original_cote_actuelle[count(tokenize(.,'\|')[normalize-space(.) = $coteOriginale])>0]][position() = last()]"/>
                                                    <xsl:variable name="positionVirt">
                                                        <xsl:for-each select="tokenize($documentALier/Acte_original_analyse,'\|')">
                                                            <xsl:variable name="position" select="position()"/>
                                                            <xsl:if test="normalize-space(.) = $analyseOriginale and normalize-space(tokenize($documentALier/Acte_original_cote_actuelle,'\|')[position() = $position]) = $coteOriginale">
                                                                <xsl:value-of select="$position"/>
                                                            </xsl:if>
                                                        </xsl:for-each>
                                                    </xsl:variable>
                                                    <xsl:value-of select="concat($debutURI,$documentALier/parent::documents/@id,'-',count($documentALier/preceding-sibling::document)+1,'-virt',$positionVirt)"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="'rien'"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                        <xsl:when test="$dateOriginale != '' and $dateOriginale != '[]'">
                                            <xsl:choose>
                                                <xsl:when test="count($document/preceding-sibling::document[Acte_original_analyse[count(tokenize(.,'\|')[normalize-space(.)=$analyseOriginale]) > 0] 
                                                    and Acte_original_date__forme_normalisée_[count(tokenize(.,'\|')[normalize-space(.)=$dateOriginale]) > 0]]) > 0">
                                                    
                                                    <xsl:variable name="documentALier" select="$document/preceding-sibling::document[Acte_original_analyse[count(tokenize(.,'\|')[normalize-space(.)=$analyseOriginale]) > 0] 
                                                        and Acte_original_date__forme_normalisée_[count(tokenize(.,'\|')[normalize-space(.)=$dateOriginale]) > 0]][position() = last()]"/>
                                                    
                                                    <xsl:variable name="positionVirt">
                                                        <xsl:for-each select="tokenize($documentALier/Acte_original_analyse,'\|')">
                                                            <xsl:variable name="position" select="position()"/>
                                                            <xsl:if test="normalize-space(.) = $analyseOriginale and normalize-space(tokenize($documentALier/Acte_original_date__forme_normalisée_,'\|')[position() = $position]) = $dateOriginale">
                                                                <xsl:value-of select="$position"/>
                                                            </xsl:if>
                                                        </xsl:for-each>
                                                    </xsl:variable>
                                                    
                                                    <xsl:value-of select="concat($debutURI,$documentALier/parent::documents/@id,'-',count($documentALier/preceding-sibling::document)+1,'-virt',$positionVirt)"/>
                                                    
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="'rien'"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="'rien'"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:if test="$aRelierURI != 'rien'">
                                    <xsl:choose>
                                        <xsl:when test="matches($type,'^vidimus','i')">
                                            <oresm-onto:estVidimusDe rdf:resource="{$aRelierURI}"></oresm-onto:estVidimusDe>
                                        </xsl:when>
                                        <xsl:when test="matches($type,'^copie|^exp','i')">
                                            <rico:isCopyOf rdf:resource="{$aRelierURI}"></rico:isCopyOf>
                                        </xsl:when>
                                        <xsl:when test="matches($type,'^extrait','i')">
                                            <oresm-onto:inclutExtraitDe rdf:resource="{$aRelierURI}"></oresm-onto:inclutExtraitDe>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:if>
                        
                    </rico:RecordResource>
            <rico:Instantiation>
                <xsl:attribute name="rdf:about">
                    <xsl:value-of select="concat('instantiation/or-', $coll, '-', $id)"/>
                </xsl:attribute>
                <rico:title xml:lang="fr">
                    <xsl:value-of select="normalize-space(Intitulé)"/>
                </rico:title>
                <rdfs:label xml:lang="fr"><xsl:value-of select="normalize-space(Intitulé)"/></rdfs:label>
                <rico:isInstantiationOf rdf:resource="{concat('recordResource/or-', $coll, '-', $id)}"></rico:isInstantiationOf>
                <xsl:choose>
                    <xsl:when test="$lieuConservation='FRAN'">
                        <oresm-onto:estActuellementConservePar rdf:resource="corporateBody/005061"/>
                    </xsl:when>
                    <xsl:when test="$lieuConservation='BIS'">
                        <oresm-onto:estActuellementConservePar rdf:resource="corporateBody/050960067"/>
                    </xsl:when>
                    <xsl:when test="$lieuConservation='FRAD060'">
                        <!-- http://www.idref.fr/028173465/id -->
                        <!-- https://francearchives.gouv.fr/fr/service/33951 -->
                        <oresm-onto:estActuellementConservePar rdf:resource="corporateBody/028173465"/>
                    </xsl:when>
                    <xsl:when test="$lieuConservation='FRAD077'">
                        <!-- http://www.idref.fr/029050421/id -->
                        <!-- https://francearchives.gouv.fr/fr/service/34157 -->
                        <oresm-onto:estActuellementConservePar rdf:resource="corporateBody/029050421"/>
                    </xsl:when>
                </xsl:choose>
            
                <xsl:if test="normalize-space(Dimensions)!=''">
                    <xsl:analyze-string select="normalize-space(Dimensions
                        )" regex="(\d+)\sx\s(\d+)\s?x?\s?(\d*)"><xsl:matching-substring>
                        <rico:height><xsl:value-of select="concat(regex-group(1), ' mm')"/></rico:height>
                        <rico:width><xsl:value-of select="concat(regex-group(2), ' mm')"/></rico:width>
                        <xsl:if test="regex-group(3)!=''">
                            <oresm-onto:epaisseur> <xsl:value-of select="concat(regex-group(3), ' mm')"/></oresm-onto:epaisseur>
                           </xsl:if>
                    </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:if>
                
                
                <xsl:if test="normalize-space(Importance_matérielle)!=''">
                    <rico:instantiationExtent xml:lang="fr"><xsl:value-of select="normalize-space(Importance_matérielle)"/></rico:instantiationExtent>
                </xsl:if>
                <xsl:if test="normalize-space(État_de_conservation_du_document)!=''">
                    <rico:integrity xml:lang="fr">
                        <xsl:value-of select="normalize-space(tokenize(État_de_conservation_du_document,'#')[not(contains(.,'[]'))])"/>
                    </rico:integrity>
                </xsl:if>
                
                <xsl:if test="Autres_descriptions_physiques[normalize-space(.)!='']">
                    <xsl:for-each select="tokenize(Autres_descriptions_physiques,'\|')">
                            <xsl:if test="not(matches(normalize-space(.),'sceau|scellé|bulle'))">
                                <rico:physicalCharacteristics xml:lang="fr">
                                    <xsl:value-of select="normalize-space(tokenize(.,'#')[not(contains(.,'[]'))])"/>
                                </rico:physicalCharacteristics>
                            </xsl:if>
                    </xsl:for-each>
                </xsl:if>
                
                <!-- DONE FLORIAN : reste à traiter les champs sur les mentions dorsales et mentions hors teneur + autres descriptions physiques-->
                
                <xsl:if test="normalize-space(Autres_mentions)!=''">
                    <oresm-onto:presenceAutreMention rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean"><xsl:value-of select="if(matches(Autres_mentions,'^non','i')) then('false') else('true')"/></oresm-onto:presenceAutreMention>
                    <xsl:if test="matches(Autres_mentions,'\[.+\]','i')">
                        <!-- La fonction replace sert à extraire le contenu entre crochet qui est (mention hors teneur au singulier ou au pluriel) en mettant le m en majuscule-->
                        <oresm-onto:descriptionAutreMention><xsl:value-of select="replace(Autres_mentions,'^.{3} \[m([^\]]+)\]','M$1')"/></oresm-onto:descriptionAutreMention>
                    </xsl:if>
                </xsl:if>
                <xsl:if test="normalize-space(Mentions_dorsales)!=''">
                    <oresm-onto:presenceMentionDorsale rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean"><xsl:value-of select="if(matches(Mentions_dorsales,'^non','i')) then('false') else('true')"/></oresm-onto:presenceMentionDorsale>
                    <xsl:choose>
                        <!-- « 1315 procuration inutile » | « M 115 » | « M 111 n° 20 (n° 21 et 22 vacat) » -->
                        <xsl:when test="contains(Mentions_dorsales,$guillemet) or contains(Mentions_dorsales,'«')">
                            <oresm-onto:transcriptionDeLaOuLesMentionsDorsales><xsl:value-of select="replace(Mentions_dorsales,'\|',';')"/></oresm-onto:transcriptionDeLaOuLesMentionsDorsales>
                        </xsl:when>
                        <xsl:when test="matches(Mentions_dorsales,'\[.+\]','i')">
                            <oresm-onto:descriptionMentionDorsale><xsl:value-of select="replace(Mentions_dorsales,'^.{3} \[m([^\]]+)\]','M$1')"/></oresm-onto:descriptionMentionDorsale>
                        </xsl:when>
                    </xsl:choose>
                </xsl:if>
                
                <xsl:if test="normalize-space(URL)!=''">
                    <rico:hasDerivedInstantiation>
                        <xsl:attribute name="rdf:resource">
                            <xsl:value-of select="concat('instantiation/or-', $coll, '-', $id, 'num')"/>
                        </xsl:attribute>
                    </rico:hasDerivedInstantiation>
                </xsl:if>
                
            </rico:Instantiation>
                    <!-- collection('../src-xml/depouillements')/documents/document/URL[normalize-space(.)!=''] -->
                    <xsl:if test="normalize-space(URL)!=''">
                        <rico:Instantiation>
                            <xsl:attribute name="rdf:about">
                                <xsl:value-of select="concat('instantiation/or-', $coll, '-', $id, 'num')"/>
                            </xsl:attribute>
                            <rdfs:seeAlso rdf:resource="{normalize-space(URL)}"/>
                        </rico:Instantiation>
                    </xsl:if>
                    
                    
                    <!-- collection('../src-xml/depouillements')/documents/document[Type_de_document='Vidimus']/Acte_original_cote_actuelle -->
                    
                    <!-- Explication traitement Actes Originaux -->
                    <!-- 
                        Acte_original_date__forme_normalisée_
                        Acte_original_analyse
                        Acte_original_cote_actuelle
                        Pour traiter les actes originaux on s'intéresse à ces 3 colonnes, il y 3 cas à concevoir :
                        - L'acte original a été dépouillé et il se trouve dans nos document, on le retrouve en comparant la valeur de Acte_original_cote_actuelle avec Cote_actuelle.
                        - L'acte original n'a pas été dépouillé, on crée un donc un nouveau recordResource à la fin du fichier actuel avec pour URI celle du document traité et le suffixe virt + la position
                        ex : recordResource/or-fortet-4-virt1
                        - L'acte original n'a pas été dépouillé mais un recordResource "virtuel" a déjà été créé dans un recordResource précédent, on doit donc les lier
                        C'est ce qui est vérifié si dessous avec la variable aCreer.
                        Pour vérifier que deux documents "virtuels" sont les mêmes on se base ou bien sur la cote qui est la même dans Acte_original_cote_actuelle ou bien sur l'analyse et la date. 
                        Si Acte_original_analyse et Acte_original_date__forme_normalisée_ ont exactement la même valeur dans un document traité précédemment (preceding-sibling::), alors on considère que ces deux actes sont les mêmes.
                        On vérifie uniquement pour les documents du même collège, il me semble qu'un acte classé dans un collège sera toujours la copie d'un acte de ce collège, à prendre en compte quand même.
                        
                        Pour le lien entre les documents "virtuels" et les dates, lieux de passages et cotes originales voir l'explication plus haut. 
                    -->
                    
                    <xsl:if test="normalize-space(Acte_original_analyse)!=''">
                        <xsl:variable name="document" select="."/>
                        <xsl:variable name="type" select="Type_de_document"/>
                        <xsl:for-each select="tokenize(./Acte_original_analyse,'\|')">
                            <xsl:variable name="position" select="position()"/>
                            <xsl:variable name="analyseOriginale" select="normalize-space(.)"/>
                            <xsl:variable name="coteOriginale" select="normalize-space(tokenize($document/Acte_original_cote_actuelle,'\|')[position() = $position])"/>
                            <xsl:variable name="dateOriginale" select="normalize-space(tokenize($document/Acte_original_date__forme_normalisée_,'\|')[position() = $position])"/>
                            
                            <xsl:variable name="aCreer">
                                <xsl:choose>
                                    <xsl:when test="$coteOriginale != '' and $coteOriginale != '[]' and not(matches($type,'^cartulaire','i'))">
                                        <!-- Si un document a pour Cote_actuelle celle de l'acte original alors il n'est pas a créer, idem pour Acte_original_cote_actuelle si un document qui précède celui-ci
                                            a la même Acte_original_cote_actuelle alors il n'est pas à créer
                                            Même logique pour Acte_original_analyse et Acte_original_date__forme_normalisée_ -->
                                        <xsl:value-of select="count($fichiersDept/documents/document/Cote_actuelle[normalize-space(.) = $coteOriginale]) = 0
                                            and count($document/preceding-sibling::document[Acte_original_cote_actuelle[count(tokenize(.,'\|')[normalize-space(.) = $coteOriginale])>0]]) = 0"/>
                                    </xsl:when>
                                    <xsl:when test="$dateOriginale != '' and $dateOriginale != '[]'  and not(matches($type,'^cartulaire','i'))">
                                        <xsl:value-of select="count($document/preceding-sibling::document[Acte_original_analyse[count(tokenize(.,'\|')[normalize-space(.)=$analyseOriginale]) > 0] 
                                            and Acte_original_date__forme_normalisée_[count(tokenize(.,'\|')[normalize-space(.)=$dateOriginale]) > 0]]) = 0"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="true()"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>

                            <xsl:if test="$aCreer = true()">
                                <rico:RecordResource rdf:about="recordResource/or-{$coll}-{$id}-virt{$position}">
                                    <rdfs:label xml:lang="fr"><xsl:value-of select="$analyseOriginale"></xsl:value-of></rdfs:label>
                                    <rico:title xml:lang="fr"><xsl:value-of select="$analyseOriginale"></xsl:value-of></rico:title>
                                    <xsl:choose>
                                        <xsl:when test="matches($type,'^vidimus','i')">
                                            <oresm-onto:aPourVidimus rdf:resource="recordResource/or-{$coll}-{$id}"/>
                                        </xsl:when>
                                        <xsl:when test="matches($type,'^copie|^exp','i')">
                                            <rico:hasCopy rdf:resource="recordResource/or-{$coll}-{$id}"/>
                                        </xsl:when>
                                        <xsl:when test="matches($type,'^extrait','i')">
                                            <oresm-onto:estExtraitDans rdf:resource="recordResource/or-{$coll}-{$id}"/>
                                            
                                        </xsl:when>
                                        
                                        <!-- Regle spécifique au cartulaire 
                                        On a considéré qu'un cartulaire est un recordResource qui est composé de plusieurs recordResource qui sont eux même des copies de document déjà dépouillé si on peut faire le lien.
                                        Par rapport aux autres actes on fait donc une étape en plus avec la logique de hasOrHadPart
                                        -->
                                        <xsl:when test="matches($type,'^cartulaire','i')">
                                            <rico:isOrWasPartOf rdf:resource="recordResource/or-{$coll}-{$id}"/>
                                            <xsl:if test="$coteOriginale != '' and $coteOriginale != '[]' and count($fichiersDept/documents/document/Cote_actuelle[normalize-space(.) = $coteOriginale]) > 0">
                                                <xsl:variable name="documentARelier" select="$fichiersDept/documents/document[Cote_actuelle[normalize-space(.) = $coteOriginale]!='']"/>
                                                <rico:isCopyOf rdf:resource="recordResource/or-{$documentARelier/parent::documents/@id}-{count($documentARelier/preceding-sibling::document)+1}"></rico:isCopyOf>
                                                <rico:descriptiveNote>Pièce faisant partie d'un cartulaire, il n'a pas de cote puisqu'il représente une partie du cartulaire qui lui est coté.</rico:descriptiveNote>
                                            </xsl:if>
                                        </xsl:when>
                                    </xsl:choose>
                                    <!-- Noeud blanc pour indiquer la cote de l'acte original, puisque les relations ont pour domaine l'instantiation et pas le record-->
                                    <xsl:if test="$coteOriginale!= '' and $coteOriginale != '[]' and not(matches($type,'^cartulaire','i'))">
                                        <rico:hasInstantiation>
                                            <rico:Instantiation>
                                            <xsl:if test="starts-with($coteOriginale, 'lost-')">
                                                <rico:descriptiveNote xml:lang="fr">Acte non retrouvé à ce jour.</rico:descriptiveNote>
                                            </xsl:if>
                                                <rico:identifier><xsl:value-of select="$coteOriginale"/></rico:identifier>
                                            </rico:Instantiation>
                                        </rico:hasInstantiation>
                                    </xsl:if>
                                </rico:RecordResource>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:if>
                    
                    <!-- J'ai vérifié dans les données directement il n'y aucun acte inséré qui peut se rapporter à un autre. -->
                    
                    <xsl:if test="normalize-space(Acte_inséré_analyse)!='' and not(matches(normalize-space(Acte_inséré_analyse),'^[0-9]+$'))">
                        <xsl:variable name="cotesIns" select="Acte_inséré_cote_actuelle"/>
                        <xsl:variable name="type" select="Type_de_document"/>
                        <xsl:variable name="datesIns" select="Acte_inséré_date__forme_normalisée_"/>
                        <xsl:for-each select="tokenize(Acte_inséré_analyse,'\|')">
                            <xsl:variable name="position" select="position()"/>
                            <xsl:variable name="coteIns" select="normalize-space(tokenize($cotesIns,'\|')[position() = $position])"/>
                            <xsl:variable name="dateIns" select="normalize-space(tokenize($datesIns,'\|')[position() = $position])"/>
                            
                            <xsl:if test="not($fichiersDept/documents/document/Cote_actuelle[normalize-space(.) = $coteIns])">
                                
                                <rico:RecordResource rdf:about="recordResource/or-{$coll}-{$id}-ins{$position}">
                                    <rdfs:label xml:lang="fr"><xsl:value-of select="normalize-space(tokenize(.,'\|')[position() = $position])"></xsl:value-of></rdfs:label>
                                    <rico:title xml:lang="fr"><xsl:value-of select="normalize-space(tokenize(.,'\|')[position() = $position])"></xsl:value-of></rico:title>
                                    <oresm-onto:inclutCopieDe rdf:resource="recordResource/or-{$coll}-{$id}"/>
                                    
                                    <xsl:if test="$coteIns!= '' and $coteIns != '[]' and not(matches($type,'^cartulaire','i'))">
                                        <rico:hasInstantiation>
                                            <rico:Instantiation>
                                                <xsl:if test="starts-with($coteIns, 'lost-')">
                                                    <rico:descriptiveNote xml:lang="fr">Acte non retrouvé à ce jour.</rico:descriptiveNote>
                                                </xsl:if>
                                                <rico:identifier><xsl:value-of select="$coteIns"/></rico:identifier>
                                            </rico:Instantiation>
                                        </rico:hasInstantiation>
                                    </xsl:if>
                                </rico:RecordResource>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:if>
                    
                </rdf:RDF>
            </xsl:result-document>
        </xsl:for-each>
   </xsl:template>
    
   <!-- Solution temporaire, fonctionne bien dans les besoins actuels mais ne prend pas en compte quand dans le chiffre romain il y a une soustraction -->
   <xsl:template name="romain">
       <xsl:param name="romain"/>
       <xsl:value-of select="
           (count(tokenize($romain,'M'))-1)*1000+
           (count(tokenize($romain,'D'))-1)*500+
           (count(tokenize($romain,'C'))-1)*100+
           (count(tokenize($romain,'L'))-1)*50+
           (count(tokenize($romain,'X'))-1)*10+
           (count(tokenize($romain,'V'))-1)*5+
           (count(tokenize($romain,'I'))-1)"/>
   </xsl:template>
    <!-- Fonction pour obtenir le numéro d'un mois en lettre -->
    <xsl:template name="mois_en_nombre">
        <xsl:param name="redige"/>
        <xsl:choose>
            <xsl:when test="matches($redige,'janv','i')">01</xsl:when>
            <xsl:when test="matches($redige,'fév|fev','i')">02</xsl:when>
            <xsl:when test="matches($redige,'mars','i')">03</xsl:when>
            <xsl:when test="matches($redige,'avril','i')">04</xsl:when>
            <xsl:when test="matches($redige,'mai','i')">05</xsl:when>
            <xsl:when test="matches($redige,'juin','i')">06</xsl:when>
            <xsl:when test="matches($redige,'juillet','i')">07</xsl:when>
            <xsl:when test="matches($redige,'août|aout','i')">08</xsl:when>
            <xsl:when test="matches($redige,'septembre','i')">09</xsl:when>
            <xsl:when test="matches($redige,'octo','i')">10</xsl:when>
            <xsl:when test="matches($redige,'novem','i')">11</xsl:when>
            <xsl:when test="matches($redige,'décem|decem','i')">12</xsl:when>
        </xsl:choose>
    </xsl:template>
   
</xsl:stylesheet>


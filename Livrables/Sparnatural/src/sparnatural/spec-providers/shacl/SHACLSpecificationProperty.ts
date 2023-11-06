import { BaseRDFReader, RDF, RDFS } from "../BaseRDFReader";
import { Quad, Store } from "n3";
import factory from "@rdfjs/data-model";
import { Config } from "../../ontologies/SparnaturalConfig";
import ISpecificationProperty from "../ISpecificationProperty";
import { DASH, SH, SHACLSpecificationProvider, XSD } from "./SHACLSpecificationProvider";
import { SHACLSpecificationEntry } from "./SHACLSpecificationEntry";
import { ListWidget, SparnaturalSearchWidget, SparnaturalSearchWidgetsRegistry } from "./SHACLSearchWidgets";
import { SpecialSHACLSpecificationEntityRegistry, SpecialSHACLSpecificationEntity, SHACLSpecificationEntity } from "./SHACLSpecificationEntity";
import Datasources from "../../ontologies/SparnaturalConfigDatasources";
import ISHACLSpecificationEntity from "./ISHACLSpecificationEntity";

export class SHACLSpecificationProperty extends SHACLSpecificationEntry implements ISpecificationProperty {

  constructor(uri:string, provider: SHACLSpecificationProvider, n3store: Store<Quad>, lang: string) {
    super(uri, provider, n3store, lang);
  }

    getLabel(): string {
      // first try to read an sh:name
      let label = this._readAsLiteralWithLang(this.uri, SH.NAME, this.lang);
      // no sh:name present, read the local part of the URI
      if(!label) {
        label = SHACLSpecificationProvider.getLocalName(this.uri) as string;
      }

      return label;
    }

    getPropertyType(range:string): string | undefined {
        // select the shape on which this is applied
        // either the property shape, or one of the shape in an inner sh:or

        let rangeEntity:ISHACLSpecificationEntity;
        if(SpecialSHACLSpecificationEntityRegistry.getInstance().getRegistry().has(range)) {
          rangeEntity = SpecialSHACLSpecificationEntityRegistry.getInstance().getRegistry().get(range) as ISHACLSpecificationEntity;
        } else {
          rangeEntity = new SHACLSpecificationEntity(range,this.provider,this.store,this.lang);
        }

        var shapeUri:string|null = null;
        var orMembers = this._readAsList(factory.namedNode(this.uri), SH.OR);
        orMembers?.forEach(m => {
          if(rangeEntity.isRangeOf(this.store, m.id)) {
            shapeUri = m.id;
          }
          // recurse one level more
          var orOrMembers = this._readAsList(m.id, SH.OR);
          orOrMembers?.forEach(orOrMember => {
            if(rangeEntity.isRangeOf(this.store, orOrMember.id)) {
              shapeUri = orOrMember.id;
            }
          });
        });

        // defaults to this property shape
        if(!shapeUri) {
          shapeUri = this.uri;
        }

        let result:string[] = new Array<string>();

        // read the dash:searchWidget annotation
        this.store.getQuads(
            factory.namedNode(shapeUri),
            DASH.SEARCH_WIDGET,
            null,
            null
        ).forEach((quad:Quad) => {
            result.push(quad.object.id);
        });

        if(result.length) {
          return result[0];
        } else {
          return this.getDefaultPropertyType(shapeUri);
        }
    }

    getDefaultPropertyType(shapeUri:string): string {
      let highest:SparnaturalSearchWidget = new ListWidget();
      let highestScore:number = 0;
      for (let index = 0; index < SparnaturalSearchWidgetsRegistry.getInstance().getSearchWidgets().length; index++) {
        const currentWidget = SparnaturalSearchWidgetsRegistry.getInstance().getSearchWidgets()[index];
        let currentScore = currentWidget.score(shapeUri, this.store)
        if(currentScore > highestScore) {
          highestScore = currentScore;
          highest = currentWidget;
        }        
      }

      return highest.getUri();
    }

    omitClassCriteria(): boolean {
      // omits the class criteria iff the property shape is an sh:IRI, but with no sh:class or no sh:node
      var hasNodeKindIri = this._hasTriple(factory.namedNode(this.uri), SH.NODE_KIND, SH.IRI);

      if(hasNodeKindIri) {
        return (this.#getShClassAndShNodeRange().length == 0);
      }

      return false;
    }

    /**
     * A property is multilingual if its datatype points to rdf:langString
     */
    isMultilingual(): boolean {
      return this._hasTriple(factory.namedNode(this.uri), SH.DATATYPE, RDF.LANG_STRING)
    }

    /**
     * @returns 
     */
    getRange(): string[] {
        // first read on property shape itself
        var classes: string[] = SHACLSpecificationProperty.readShClassAndShNodeOn(this.store, this.uri);

        // nothing, see if some default can apply on the property shape itself
        if(classes.length == 0) { 
          SpecialSHACLSpecificationEntityRegistry.getInstance().getRegistry().forEach((value: SpecialSHACLSpecificationEntity, key: string) => {
            if(key != SpecialSHACLSpecificationEntityRegistry.SPECIAL_SHACL_ENTITY_OTHER) {
              if(value.isRangeOf(this.store, this.uri)) {
                classes.push(key);
              }
            }
          });
        }

        // still nothing, look on the sh:or members
        if(classes.length == 0) {
          var orMembers = this._readAsList(factory.namedNode(this.uri), SH.OR);
          orMembers?.forEach(m => {
            // read sh:class / sh:node
            var orClasses: string[] = SHACLSpecificationProperty.readShClassAndShNodeOn(this.store, m.id);

            // nothing, see if default applies on this sh:or member
            if(orClasses.length == 0) {
              SpecialSHACLSpecificationEntityRegistry.getInstance().getRegistry().forEach((value: SpecialSHACLSpecificationEntity, key: string) => {
                if(key != SpecialSHACLSpecificationEntityRegistry.SPECIAL_SHACL_ENTITY_OTHER) {
                  if(value.isRangeOf(this.store, m.id)) {
                    orClasses.push(key);
                  }
                }
              });
            }

            // still nothing, recurse one level more
            if(orClasses.length == 0) {
              var orOrMembers = this._readAsList(m.id, SH.OR);
              orOrMembers?.forEach(orOrMember => {
                // read sh:class / sh:node
                var orOrClasses: string[] = SHACLSpecificationProperty.readShClassAndShNodeOn(this.store, orOrMember.id);
                // nothing, see if default applies on this sh:or member
                if(orOrClasses.length == 0) {
                  SpecialSHACLSpecificationEntityRegistry.getInstance().getRegistry().forEach((value: SpecialSHACLSpecificationEntity, key: string) => {
                    if(key != SpecialSHACLSpecificationEntityRegistry.SPECIAL_SHACL_ENTITY_OTHER) {
                      if(value.isRangeOf(this.store, orOrMember.id)) {
                        orClasses.push(key);
                      }
                    }
                  });
                }
              });
            }

            // still nothing, add default, only if not added previously
            if(orClasses.length == 0) {
              if(orClasses.indexOf(SpecialSHACLSpecificationEntityRegistry.SPECIAL_SHACL_ENTITY_OTHER) == -1) {
                orClasses.push(SpecialSHACLSpecificationEntityRegistry.SPECIAL_SHACL_ENTITY_OTHER);
              }
            }

            // add sh:or range to final list of ranges
            classes.push(...orClasses);
          });
        }

        // still nothing, add the default
        if(classes.length == 0) {
          classes.push(SpecialSHACLSpecificationEntityRegistry.SPECIAL_SHACL_ENTITY_OTHER);
        }

        // return a dedup array
        return [...new Set(classes)];
    }

    #getShClassAndShNodeRange():string[] {
      // read the sh:class
      var classes: string[] = SHACLSpecificationProperty.readShClassAndShNodeOn(this.store, this.uri);

      // read sh:or content
      var orMembers = this._readAsList(factory.namedNode(this.uri), SH.OR);
      orMembers?.forEach(m => {
        classes.push(...SHACLSpecificationProperty.readShClassAndShNodeOn(this.store, m.id));
      });

      return classes;
  }

    static readShClassAndShNodeOn(n3store:Store<Quad>, theUri:any):string[] {         
      var classes: string[] = [];

      // read the sh:class
      const shclassQuads = n3store.getQuads(
        factory.namedNode(theUri),
        SH.CLASS,
        null,
        null
      );

      // then for each of them, find all NodeShapes targeting this class
      shclassQuads.forEach((quad:Quad) => {
          n3store.getQuads(
              null,
              SH.TARGET_CLASS,
              quad.object,
              null
          ).forEach((quad:Quad) => {
              classes.push(quad.subject.id);
          });

          // also look for nodeshapes that have directly this URI and that are themselves classes
          n3store.getQuads(
              quad.object,
              RDF.TYPE,
              RDFS.CLASS,
              null
          ).forEach((quad:Quad) => {
              classes.push(quad.subject.id);
          });
      });

      // read the sh:node
      const shnodeQuads = n3store.getQuads(
          factory.namedNode(theUri),
          SH.NODE,
          null,
          null
      ).forEach((quad:Quad) => {
          classes.push(quad.object.id);
      });  
      
      return classes;
    }

    getDatasource() {
      return this._readDatasourceAnnotationProperty(
          this.uri,
          Datasources.DATASOURCE
      );
    }

    getTreeChildrenDatasource() {
      return this._readDatasourceAnnotationProperty(
          this.uri,
          Datasources.TREE_CHILDREN_DATASOURCE
        );
    }

    getTreeRootsDatasource() {
      return this._readDatasourceAnnotationProperty(
          this.uri,
          Datasources.TREE_ROOTS_DATASOURCE
      );
    }

    getBeginDateProperty(): string | null {
      return this._readAsSingleResource(this.uri, Config.BEGIN_DATE_PROPERTY);
    }
  
    getEndDateProperty(): string | null {
      return this._readAsSingleResource(this.uri, Config.END_DATE_PROPERTY);
    }
  
    getExactDateProperty(): string | null {
      return this._readAsSingleResource(this.uri, Config.EXACT_DATE_PROPERTY);
    }
  
    isEnablingNegation(): boolean {
      return !(
        this._readAsSingleLiteral(this.uri, Config.ENABLE_NEGATION) == "false"
      );
    }
  
    isEnablingOptional(): boolean {
      return !(
        this._readAsSingleLiteral(this.uri, Config.ENABLE_OPTIONAL) == "false"
      );
    }
  
    getServiceEndpoint(): string | null {
      const service = this._readAsSingleResource(this.uri,Config.SPARQL_SERVICE);
      if(service) {
        const endpoint = this._readAsSingleResource(service,Config.ENDPOINT);
        if (endpoint) {
          return endpoint;
        } 
      }    
      return null;
    }
  
    isLogicallyExecutedAfter(): boolean {
      var executedAfter = this._readAsSingleLiteral(this.uri, Config.SPARNATURAL_CONFIG_CORE+"executedAfter");
      return executedAfter;
    }
}
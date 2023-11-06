import LocalCacheData from "../../../datastorage/LocalCacheData";
import ISettings from "../../../settings/ISettings";


/**
 * Fetches a URL
 */
export class UrlFetcher {

    private localCacheDataTtl:number;
    // private extraHeaders: Map<string, string>;
    private extraHeaders: any;

    // private constructor
    private constructor(localCacheDataTtl:any, extraHeaders:Map<string,string>) {
        this.localCacheDataTtl = localCacheDataTtl;
        this.extraHeaders = extraHeaders;
        
    }

    // static factory builder method from settings
    static build(settings:ISettings):UrlFetcher {
        return new UrlFetcher(settings.localCacheDataTtl, settings.headers);
    }

    fetchUrl(
        url:string,
        callback: (data: {}) => void
    ): void {
    
        var headers = new Headers();
        // honor extra headers
        for (const k in this.extraHeaders) {
            headers.append(k, this.extraHeaders[k]);
        }
        headers.append(
            "Accept",
            "application/sparql-results+json, application/json, */*;q=0.01"
        );
        let init = {
            method: "GET",
            headers: headers,
            mode: "cors",
            cache: "default"
        };
        
        let temp = new LocalCacheData();
        let fetchpromise = temp.fetch(url, init, this.localCacheDataTtl);

        fetchpromise
        .then((response: { json: () => any }) => response.json())
        .then((data: any) => {
            callback(data);
        });
    }

}

/**
 * Executes a SPARQL query against the triplestore
 */
export class SparqlFetcher {

    urlFetcher:UrlFetcher;
    sparqlEndpointUrl: any;
  
    constructor(
        urlFetcher:UrlFetcher,
        sparqlEndpointUrl: any
    ) {
        this.urlFetcher = urlFetcher,
        this.sparqlEndpointUrl = sparqlEndpointUrl;
    }

    buildUrl(sparql:string):string {
        var separator = this.sparqlEndpointUrl.indexOf("?") > 0 ? "&" : "?";

        var url =
            this.sparqlEndpointUrl +
            separator +
            "query=" +
            encodeURIComponent(sparql) +
            "&format=json";

        return url;
    }

    executeSparql(
        sparql:string,
        callback: (data: any) => void
    ) {
        let url = this.buildUrl(sparql);

        this.urlFetcher.fetchUrl(
            url,
            callback
        );
    }
}
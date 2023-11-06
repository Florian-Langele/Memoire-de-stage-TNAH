import * as DataFactory from "@rdfjs/data-model" ;
import { BgpPattern, Pattern, ValuePatternRow, ValuesPattern } from "sparqljs";
import { getSettings } from "../../../sparnatural/settings/defaultSettings";
import { SelectedVal } from "../../generators/ISparJson";
import WidgetWrapper from "../builder-section/groupwrapper/criteriagroup/edit-components/WidgetWrapper";
import { AbstractWidget, ValueRepetition, WidgetValue } from "./AbstractWidget";
import { SelectAllValue } from "../builder-section/groupwrapper/criteriagroup/edit-components/EditComponents";
import EndClassGroup from "../builder-section/groupwrapper/criteriagroup/startendclassgroup/EndClassGroup";

export class BooleanWidgetValue implements WidgetValue {
  value: {
    label: string;
    boolean: boolean;
  }

  key():string {
    return this.value.boolean.toString();
  }

  constructor(v:BooleanWidgetValue["value"]) {
    this.value = v;
  }
}

export class BooleanWidget extends AbstractWidget {
  protected widgetValues: BooleanWidgetValue[];
  constructor(
    parentComponent: WidgetWrapper,
    startClassVal: SelectedVal,
    objectPropVal: SelectedVal,
    endClassVal: SelectedVal
  ) {
    super(
      "boolean-widget",
      parentComponent,
      null,
      startClassVal,
      objectPropVal,
      endClassVal,
      ValueRepetition.SINGLE
    );
  }

  render() {
    super.render();
    let trueSpan = $(
      `<span class="boolean-value">${getSettings().langSearch.true}</span>'`
    );
    let orSpan = $(`<span class="or">&nbsp;${getSettings().langSearch.Or}&nbsp;</span>`);
    let falseSpan = $(
      `<span class="boolean-value"">${getSettings().langSearch.false}</span>`
    );
    this.html.append(trueSpan).append(orSpan).append(falseSpan);

    trueSpan[0].addEventListener("click", (e) => {
      let widgetValue: BooleanWidgetValue = new BooleanWidgetValue({
        label: getSettings().langSearch.true,
        boolean: true,
      });

      this.renderWidgetVal(widgetValue);
    });

    falseSpan[0].addEventListener("click", (e) => {
      let widgetValue: BooleanWidgetValue = new BooleanWidgetValue({
        label: getSettings().langSearch.false,
        boolean: false,
      });

      this.renderWidgetVal(widgetValue);
    });
    return this;
  }

  parseInput(input: BooleanWidgetValue["value"]): BooleanWidgetValue {
    return new BooleanWidgetValue(input);
   }

   /**
    * Blocks if a value is selected and this is not the "all" special value
    * @returns true
    */
   isBlockingObjectProp() {
    return (
      this.widgetValues.length == 1
      &&
      !(this.widgetValues[0] instanceof SelectAllValue)
      &&
      !((this.ParentComponent.ParentComponent.ParentComponent as EndClassGroup).isVarSelected())
    );
   }

  getRdfJsPattern(): Pattern[] {
    // if we are blocking the object prop, we create it directly here with the value as the object
    if(this.isBlockingObjectProp()) {
      let ptrn: BgpPattern = {
        type: "bgp",
        triples: [
          {
            subject: DataFactory.variable(this.getVariableValue(this.startClassVal)),
            predicate: DataFactory.namedNode(this.objectPropVal.type),
            object: DataFactory.literal(
              this.widgetValues[0].value.boolean.toString(),
              DataFactory.namedNode("http://www.w3.org/2001/XMLSchema#boolean")
            ),
          },
        ],
      };
      return [ptrn];
    } else {
      // otherwise the object prop is created and we create a VALUES clause with the actual boolean
      let vals = (this.widgetValues as BooleanWidgetValue[]).map((v) => {
        let vl: ValuePatternRow = {};
        vl[this.endClassVal.variable] = DataFactory.literal(
          this.widgetValues[0].value.boolean.toString(),
          DataFactory.namedNode("http://www.w3.org/2001/XMLSchema#boolean")
        );
        return vl;
      });
      let valuePattern: ValuesPattern = {
        type: "values",
        values: vals,
      };
      return [valuePattern];
    }
  }
}

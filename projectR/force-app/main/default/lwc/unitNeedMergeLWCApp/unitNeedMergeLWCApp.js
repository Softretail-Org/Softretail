/* eslint-disable no-empty */
/* eslint-disable no-redeclare */
/* eslint-disable no-loop-func */
/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-useless-escape */
/* eslint-disable vars-on-top */
/* eslint-disable guard-for-in */
/* eslint-disable no-console */
import {
  LightningElement,
  wire,
  track,
  api
} from "lwc";
import getTableColumns from "@salesforce/apex/UnitNeedMergeLWCController.getTableColumns";
import fetchUnitNeedRecords from "@salesforce/apex/UnitNeedMergeLWCController.fetchUnitNeedRecords";
import fetchUnitNeedRecordsCount from "@salesforce/apex/UnitNeedMergeLWCController.fetchUnitNeedRecordsCount";
import fetchProductRecords from "@salesforce/apex/UnitNeedMergeLWCController.fetchProductRecords";
import fetchProductRecordsCount from "@salesforce/apex/UnitNeedMergeLWCController.fetchProductRecordsCount";
import fetchProductsProductCodeRecordsByProductCodeSearchTerm from "@salesforce/apex/UnitNeedMergeLWCController.fetchProductsProductCodeRecordsByProductCodeSearchTerm";
import saveUnitNeed from "@salesforce/apex/UnitNeedMergeLWCController.saveUnitNeed";
import validateUniteNeedlink from "@salesforce/apex/UnitNeedMergeLWCController.validateUniteNeedlink";
import MSG_Application_Error from "@salesforce/label/c.MSG_Application_Error";
import MSG_Error_Retrieving_Data from "@salesforce/label/c.MSG_Error_Retrieving_Data";
import MSG_Error_Saving_Data from "@salesforce/label/c.MSG_Error_Saving_Data";
import MSG_Product_Code_Already_Assigned from "@salesforce/label/c.MSG_Product_Code_Already_Assigned";
import MSG_Error_Validating_Data from "@salesforce/label/c.MSG_Error_Validating_Data";
import LBL_Unit_Needs from "@salesforce/label/c.LBL_Unit_Needs";
import LBL_No_Item_To_Display from "@salesforce/label/c.LBL_No_Item_To_Display";
import Save from "@salesforce/label/c.Save";
import Cancel from "@salesforce/label/c.Cancel";
import LBL_Search_Unit_Need from "@salesforce/label/c.LBL_Search_Unit_Need";
import LBL_First from "@salesforce/label/c.LBL_First";
import LBL_Previous from "@salesforce/label/c.LBL_Previous";
import LBL_Next from "@salesforce/label/c.LBL_Next";
import LBL_Last from "@salesforce/label/c.LBL_Last";
import LBL_Search_Product from "@salesforce/label/c.LBL_Search_Product";
import Comments from "@salesforce/label/c.Comments";
import Status from "@salesforce/label/c.Status";
import Products from "@salesforce/label/c.Products";
import LBL_Of from "@salesforce/label/c.LBL_Of";
import LBL_Linked_Product from "@salesforce/label/c.LBL_Linked_Product";
import LBL_Product_Code from "@salesforce/label/c.LBL_Product_Code";
import MSG_Products_Merged_Successfully from "@salesforce/label/c.MSG_Products_Merged_Successfully";
import MSG_Error_Occurred from "@salesforce/label/c.MSG_Error_Occurred";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class UnitNeedMergeLWCApp extends NavigationMixin(LightningElement) {
  @track loading;
  @track UnitNeedcolumns = [];
  @track Productcolumns = [];
  @track UnitNeedtableLoadingState = true;
  @track searchTermProduct = "";
  @track searchTermUnitNeed = "";
  @track pageSizeString = "10";
  @track pageSizeInteger = 10;
  @track DisplayedUnitNeedData = [];
  @track DisplayedProductData = [];
  @track ProducttableLoadingState = true;
  @track disabledFirstPreviousProduct;
  @track disabledFirstPreviousUnitNeed;
  @track disabledLastNextProduct;
  @track disabledLastNextUnitNeed;
  @track SearchedCategories = "";
  @track globalErrorMessage = "";
  @track globalErrorMessageBool = "";
  @track isUnitNeedDataPresent = false;
  @track isProductDataPresent = false;
  LBL_Unit_Needs = LBL_Unit_Needs;
  //labels
  LBL_Unit_Needs = LBL_Unit_Needs;
  LBL_No_Item_To_Display = LBL_No_Item_To_Display;
  Save = Save;
  Cancel = Cancel;
  LBL_Search_Unit_Need = LBL_Search_Unit_Need;
  LBL_First = LBL_First;
  LBL_Previous = LBL_Previous;
  LBL_Next = LBL_Next;
  LBL_Last = LBL_Last;
  LBL_Search_Product = LBL_Search_Product;
  Products = Products;
  LBL_Of = LBL_Of;
  LBL_Linked_Product = LBL_Linked_Product;
  MSG_Products_Merged_Successfully = MSG_Products_Merged_Successfully;
  MSG_Error_Occurred = MSG_Error_Occurred;
  Comments = Comments;
  Status = Status;
  LBL_Product_Code = LBL_Product_Code;
  //////////////
  unitNeedToMerge = {};
  productPageStart = 1;
  productPageEnd;
  unitNeedPageStart = 1;
  unitNeedPageEnd;
  sortedFieldName;
  sortDirection;
  productOffSet = 0;
  unitNeedOffSet = 0;
  productCount;
  unitNeedCount;
  @track productPagesBadge = "";
  @track unitNeedPagesBadge = "";
  @track saveComplete = false;
  @track ErrorMessage = "";
  @track InformationMessage = "";
  @api unitNeedIds = "";
  unitNeedFieldsAPIs = [
    "Category__r.Name",
    "Category__c",
    "Name",
    "ProductCode",
    "Average_Weekly_Sales_Hyper__c",
    "Retail_Price_Reco__c"
  ];
  displayedUnitNeedFieldsAPIs = [
    "Name",
    "ProductCode",
    "Average_Weekly_Sales_Hyper__c",
    "Retail_Price_Reco__c"
  ];
  productFieldsAPIs = [
    "Category__r.Name",
    "Category__c",
    "Name",
    "ProductCode",
    "Product_EAN__c",
    "Status__c"
  ];
  displayedProductFieldsAPIs = [
    "Name",
    "ProductCode",
    "Product_EAN__c",
    "Status__c"
  ];
  editableUnitNeedFieldsAPIs = ["ProductCode"];
  @track ProductNormalTableData = [];
  @track ProductNormalTableDataByCategory = [];
  @track UnitNeedNormalTableData = [];
  @track UnitNeedNormalTableDataByCategory = [];
  @track UnitNeedNormalTableDataInOutByCategory = [];
  @track divLookAHeadStyle = 'display: none;';
  @track productCodeSearchTerm = '';
  @track divLookAHeadData = [];
  UnitNeedNormalTableDataInOut = [];
  connectedCallback() {
    this.loading = true;
    this.UnitNeedtableLoadingState = true;
    this.ProducttableLoadingState = true;
  }
  @wire(fetchProductsProductCodeRecordsByProductCodeSearchTerm, {
    SearchTerm: "$productCodeSearchTerm"
  })
  fetchProductsProductCodeRecordsByProductCodeSearchTerm(result) {
    this.divLookAHeadData = [];
    if (result.data) {
      //console.log(result.data);
      var data = JSON.parse(result.data);
      for (var index in data) {
        //console.log(data[index].ProductCode);
        this.divLookAHeadData.push({
          label: data[index].ProductCode,
          value: data[index].ProductCode
        });
      }
    }
  }
  @wire(fetchUnitNeedRecordsCount, {
    SearchTerm: "$searchTermUnitNeed",
    unitNeedIds: "$unitNeedIds"
  })
  fetchUnitNeedRecordsCount(result) {
    if (result.data) {
      this.unitNeedCount = Number(JSON.parse(result.data));
    }
    this.setDisplayedData();
  }
  @wire(fetchProductRecordsCount, {
    SearchTerm: "$searchTermProduct",
    SearchedCategories: "$SearchedCategories"
  })
  fetchProductRecordsCount(result) {
    if (result.data) {
      this.productCount = Number(JSON.parse(result.data));
    }
    this.setDisplayedData();
  }
  @wire(fetchUnitNeedRecords, {
    SearchTerm: "$searchTermUnitNeed",
    unitNeedIds: "$unitNeedIds",
    LimitSize: "$pageSizeInteger",
    offset: "$unitNeedOffSet"
  }) fetchUnitNeedRecordsResultsNoneCachable;
  @wire(fetchUnitNeedRecords, {
    SearchTerm: "$searchTermUnitNeed",
    unitNeedIds: "$unitNeedIds",
    LimitSize: "$pageSizeInteger",
    offset: "$unitNeedOffSet"
  })
  fetchUnitNeedRecordsResults(result) {
    this.loading = true;
    this.DisplayedUnitNeedData = [];
    this.UnitNeedNormalTableData = [];
    this.UnitNeedNormalTableDataInOutByCategory = [];
    this.UnitNeedNormalTableDataInOut = [];
    this.UnitNeedtableLoadingState = true;
    var SearchedCategories = "";
    if (result.data) {
      var listData = JSON.parse(result.data);
      for (var index in listData) {
        var row = new Map();
        var NormalTableRow = [];
        var InOutRow = [];
        row.Id = listData[index].Id;
        for (var index2 in this.unitNeedFieldsAPIs) {
          var apiName = this.unitNeedFieldsAPIs[index2];
          var data;
          if (apiName.includes("__r")) {
            var apiNameSplited = apiName.split(".");
            data = listData[index];
            while (apiNameSplited.length > 0) {
              data = data[apiNameSplited[0]];
              apiNameSplited.shift();
            }
          } else {
            data = listData[index][apiName];
          }
          row[apiName] = data;
          NormalTableRow.push(data);
          if (this.editableUnitNeedFieldsAPIs.includes(apiName)) {
            if (this.unitNeedToMerge[row.Id] && this.unitNeedToMerge[row.Id].ProductCode) {
              InOutRow.push({
                isInput: true,
                data: this.unitNeedToMerge[row.Id].ProductCode,
                Id: row.Id
              });
              console.log("row.Id:" + row.Id);
            } else {
              InOutRow.push({
                isInput: true,
                data: "",
                Id: row.Id
              });
            }
          } else {
            InOutRow.push({
              isInput: false,
              data: data,
              Id: row.Id
            });
          }
        }
        if (listData[index].Category__c) {
          SearchedCategories =
            index !== listData.length - 1 ?
              SearchedCategories + listData[index].Category__c + ";" :
              SearchedCategories + listData[index].Category__c;
        }
        this.DisplayedUnitNeedData.push(row);
        this.UnitNeedNormalTableData.push(NormalTableRow);
        this.UnitNeedNormalTableDataInOut.push(InOutRow);
      }
      var catIdToNameMap = {};
      var map = {};
      for (var index in this.UnitNeedNormalTableData) {
        var self = this;
        catIdToNameMap[this.UnitNeedNormalTableData[index][1]]=this.UnitNeedNormalTableData[index][0];
        map[
          this.UnitNeedNormalTableData[index][1]
        ] = this.UnitNeedNormalTableData.filter(item => {
          return self.UnitNeedNormalTableData[index][1] === item[1];
        });
      }
      for (var category in map) {
        var categoryId = category;
        var listUnitNeed = map[categoryId];
        for (var index = 0; index < listUnitNeed.length; index++) {
          listUnitNeed[index].splice(0, 2);
        }
        this.UnitNeedNormalTableDataByCategory.push({
          categoryId: category,
          listUnitNeed: listUnitNeed
        });
      }
      map = {};
      for (var index in this.UnitNeedNormalTableDataInOut) {
        var self = this;
        catIdToNameMap[this.UnitNeedNormalTableData[index][1]]=this.UnitNeedNormalTableData[index][0];
        map[
          this.UnitNeedNormalTableDataInOut[index][1].data
        ] = this.UnitNeedNormalTableDataInOut.filter(item => {
          return self.UnitNeedNormalTableDataInOut[index][1].data === item[1].data;
        });
      }
      for (var category in map) {
        var categoryId = category;
        var listUnitNeed = map[categoryId];
        for (var index = 0; index < listUnitNeed.length; index++) {
          listUnitNeed[index].splice(0, 2);
        }
        this.UnitNeedNormalTableDataInOutByCategory.push({
          categoryName: catIdToNameMap[categoryId],
          URL: '/'+categoryId,
          listUnitNeed: listUnitNeed
        });
      }
      console.log("UnitNeedNormalTableDataInOutByCategory:" + JSON.stringify(this.UnitNeedNormalTableDataInOutByCategory));
      this.SearchedCategories = SearchedCategories;
      this.productOffSet = 0;
      this.isUnitNeedDataPresent = this.UnitNeedNormalTableData.length === 0 ? false : true;
    } else {
      this.toastError(MSG_Application_Error, MSG_Error_Retrieving_Data);
    }
    this.setDisplayedData();
    var self = this;
    setTimeout(() => {
      self.UnitNeedtableLoadingState = false;
    }, 1000);
    this.loading = false;
  }
  @wire(fetchProductRecords, {
    SearchTerm: "$searchTermProduct",
    SearchedCategories: "$SearchedCategories",
    LimitSize: "$pageSizeInteger",
    offset: "$productOffSet"
  })
  fetchProductRecordsResults(result) {
    this.loading = true;
    this.DisplayedProductData = [];
    this.ProductNormalTableData = [];
    this.ProductNormalTableDataByCategory = [];
    if (result.data) {
      this.ProductData = [];
      var listData = JSON.parse(result.data);
      for (var index in listData) {
        var row = new Map();
        var NormalTableRow = [];
        row.Id = listData[index].Id;
        for (var index2 in this.productFieldsAPIs) {
          var apiName = this.productFieldsAPIs[index2];
          var data;
          if (apiName.includes("__r")) {
            var apiNameSplited = apiName.split(".");
            data = listData[index];
            while (apiNameSplited.length > 0) {
              data = data[apiNameSplited[0]];
              apiNameSplited.shift();
            }
          } else {
            data = listData[index][apiName];
          }
          row[apiName] = data;
          NormalTableRow.push(data);
        }
        this.DisplayedProductData.push(row);
        this.ProductNormalTableData.push(NormalTableRow);
      }
      var catIdToNameMap = {};
      var map = {};
      for (var index in this.ProductNormalTableData) {
        var self = this;
        catIdToNameMap[this.ProductNormalTableData[index][1]]=this.ProductNormalTableData[index][0];
        map[
          this.ProductNormalTableData[index][1]
        ] = this.ProductNormalTableData.filter(item => {
          return self.ProductNormalTableData[index][1] === item[1];
        });
      }
      for (var category in map) {
        var categoryId = category;
        var listProduct = map[categoryId];
        for (var index = 0; index < listProduct.length; index++) {
          listProduct[index].splice(0, 2);
        }
        this.ProductNormalTableDataByCategory.push({
          categoryName: catIdToNameMap[categoryId],
          URL: '/'+categoryId,
          listProduct: listProduct
        });
      }
      this.isProductDataPresent = this.ProductNormalTableData.length === 0 ? false : true;

    } else {
      this.toastError(MSG_Application_Error, MSG_Error_Retrieving_Data);
    }
    this.setDisplayedData();
    var self = this;
    setTimeout(() => {
      self.ProducttableLoadingState = false;
    }, 1000);
    this.loading = false;
    //console.log("columns" + JSON.stringify(this.DisplayedProductData));
  }

  @wire(getTableColumns, {
    objectName: "Product2",
    fieldsName: "$displayedUnitNeedFieldsAPIs"
  })
  getUnitNeedTableColumns(result) {
    if (result.data) {
      this.UnitNeedcolumns = JSON.parse(result.data);
      for (var index in this.UnitNeedcolumns) {
        this.UnitNeedcolumns[index].sortable = true;
        if (
          this.editableUnitNeedFieldsAPIs.includes(
            this.UnitNeedcolumns[index].fieldName
          )
        ) {
          this.UnitNeedcolumns[index].editable = true;
        } else {
          this.UnitNeedcolumns[index].editable = false;
        }
      }
    } else {
      this.toastError(MSG_Application_Error, MSG_Error_Retrieving_Data);
    }
  }
  @wire(getTableColumns, {
    objectName: "Product2",
    fieldsName: "$displayedProductFieldsAPIs"
  })
  getProductTableColumns(result) {
    if (result.data) {
      this.Productcolumns = JSON.parse(result.data);
    } else {
      this.toastError(MSG_Application_Error, MSG_Error_Retrieving_Data);
    }
  }
  toastError(title, msg) {
    const evt = new ShowToastEvent({
      title: title,
      message: msg,
      variant: "error",
      mode: "dismissable"
    });
    this.dispatchEvent(evt);
  }
  toastSuccess(title, msg) {
    const evt = new ShowToastEvent({
      title: title,
      message: msg,
      variant: "success",
      mode: "dismissable"
    });
    this.dispatchEvent(evt);
  }
  changeInputHandler(event) {
    if ((!event.target.value || (event.target.value && event.which === 13)) && this[event.target.name] !== event.target.value) {
      this[event.target.name] = event.target.value;
      if (event.target.name.includes("Product")) {
        this.productOffSet = 0;
      }
      if (event.target.name.includes("UnitNeed")) {
        this.unitNeedOffSet = 0;
        this.productOffSet = 0;
      }
    }
  }

  get getPageSizeOptions() {
    return [{
      label: "10",
      value: "10"
    },
    {
      label: "25",
      value: "25"
    },
    {
      label: "50",
      value: "50"
    },
    {
      label: "100",
      value: "100"
    }
    ];
  }

  pageSizeChangeHandler(event) {
    this.pageSizeString = event.detail.value;
    this.pageSizeInteger = Number(this.pageSizeString);
    this.productOffSet = 0;
    this.unitNeedOffSet = 0;
  }
  pageChangeHandler(event) {
    var target = event.target;
    var buttonName = target.name;
    if (buttonName === "Next-Product") {
      if (this.productOffSet <= this.productCount - this.pageSizeInteger) {
        this.productOffSet += this.pageSizeInteger;
      }
    }
    if (buttonName === "Previous-Product") {
      if (this.productOffSet >= this.pageSizeInteger) {
        this.productOffSet = this.productOffSet - this.pageSizeInteger;
      }
    }
    if (buttonName === "First-Product") {
      this.productOffSet = 0;
    }
    if (buttonName === "Last-Product") {
      this.productOffSet =
        Math.floor(this.productCount / this.pageSizeInteger) *
          this.pageSizeInteger ===
          this.productCount ?
          this.productCount - this.pageSizeInteger :
          Math.floor(this.productCount / this.pageSizeInteger) *
          this.pageSizeInteger;
    }
    if (buttonName === "Next-UnitNeed") {
      if (this.unitNeedOffSet <= this.unitNeedCount - this.pageSizeInteger) {
        this.unitNeedOffSet += this.pageSizeInteger;
      }
    }
    if (buttonName === "Previous-UnitNeed") {
      if (this.unitNeedOffSet >= this.pageSizeInteger) {
        this.unitNeedOffSet = this.unitNeedOffSet - this.pageSizeInteger;
      }
    }
    if (buttonName === "First-UnitNeed") {
      this.unitNeedOffSet = 0;
    }
    if (buttonName === "Last-UnitNeed") {
      this.unitNeedOffSet =
        Math.floor(this.unitNeedCount / this.pageSizeInteger) *
          this.pageSizeInteger ===
          this.unitNeedCount ?
          this.unitNeedCount - this.pageSizeInteger :
          Math.floor(this.unitNeedCount / this.pageSizeInteger) *
          this.pageSizeInteger;
    }
  }
  setDisplayedData() {
    this.setButtons();
    var unitNeedPageStart = this.unitNeedOffSet;
    var productPageStart = this.productOffSet;
    var unitNeedPageEnd = Math.min(
      this.unitNeedCount,
      this.unitNeedOffSet + this.pageSizeInteger
    );
    var productPageEnd = Math.min(
      this.productCount,
      this.productOffSet + this.pageSizeInteger
    );
    if (this.productCount) {
      this.productPageStart = productPageStart + 1;
      this.productPageEnd = productPageEnd;
    } else {
      this.productPageStart = 0;
      this.productPageEnd = 0;
    }
    if (this.unitNeedCount) {
      this.unitNeedPageStart = unitNeedPageStart + 1;
      this.unitNeedPageEnd = unitNeedPageEnd;
    } else {
      this.unitNeedPageStart = 0;
      this.unitNeedPageEnd = 0;
    }
    this.productPagesBadge =
      this.productPageStart +
      "-" +
      this.productPageEnd +
      " " +
      this.LBL_Of +
      " " +
      this.productCount;
    this.unitNeedPagesBadge =
      this.unitNeedPageStart +
      "-" +
      this.unitNeedPageEnd +
      " " +
      this.LBL_Of +
      " " +
      this.unitNeedCount;
  }
  setButtons() {
    if (this.productOffSet === 0) {
      this.disabledFirstPreviousProduct = true;
    } else {
      this.disabledFirstPreviousProduct = false;
    }
    if (this.productOffSet >= this.productCount - this.pageSizeInteger) {
      this.disabledLastNextProduct = true;
    } else {
      this.disabledLastNextProduct = false;
    }
    if (this.unitNeedOffSet === 0) {
      this.disabledFirstPreviousUnitNeed = true;
    } else {
      this.disabledFirstPreviousUnitNeed = false;
    }
    if (this.unitNeedOffSet >= this.unitNeedCount - this.pageSizeInteger) {
      this.disabledLastNextUnitNeed = true;
    } else {
      this.disabledLastNextUnitNeed = false;
    }
  }
  saveUnitNeed() {
    var draftValues = [];
    for (var key in this.unitNeedToMerge) {
      draftValues.push(this.unitNeedToMerge[key]);
    }
    if (draftValues.length === 0) {
      this.toastError(MSG_Application_Error, "No Unit Need To Merge");
      return;
    }
    var unitNeedToSave = JSON.stringify(draftValues);
    var self = this;
    saveUnitNeed({
      data: unitNeedToSave
    })
      .then(result => {
        var SaveResultWrapper = JSON.parse(result);
        self.generateMessage(SaveResultWrapper);
        if (SaveResultWrapper.isSuccess) {
          console.log('success');
          //refreshApex(self.fetchUnitNeedRecordsResultsNoneCachable);
        } else {
          self.toastError(MSG_Application_Error, MSG_Error_Saving_Data);
          console.log('no success');
          this.error = true;
          self.toastError(MSG_Application_Error, SaveResultWrapper.errorMessage);
        }
        self.saveComplete = true;
      });
  }
  /*cellChangeHandler() {
    var table = this.template.querySelector('[data-id="uniteNeedTable"]');
    var draftValues = table.draftValues;
    var self = this;
    table.draftValues = [];
    for (var index = 0; index < draftValues.length; index++) {
      var row = draftValues[index];
      if (!row.ProductCode) {
        delete this.unitNeedToMerge[row.Id];
      } else if (this.alreadyExistInDraftsDiffrentId(row.Id, row.ProductCode)) {
        delete this.unitNeedToMerge[row.Id];
        this.toastError(
          MSG_Application_Error,
          MSG_Product_Code_Already_Assigned
        );
      } else if (this.alreadyExistInDraftsSameId(row.Id, row.ProductCode)) {
        continue;
      } else {
        validateUniteNeedlink({
          uniteNeedId: row.Id,
          productCode: row.ProductCode
        })
          .then(data => {
            var validation = JSON.parse(data);
            if (validation.isValid) {
              self.toastSuccess(validation.status, validation.comment);
              if (row.ProductCode) {
                self.unitNeedToMerge[row.Id] = row;
                var drafts = [];
                for (var Id in self.unitNeedToMerge) {
                  drafts.push(self.unitNeedToMerge[Id]);
                }
                table.draftValues = drafts;
              }
            } else {
              delete self.unitNeedToMerge[row.Id];
              self.toastError(validation.status, validation.comment);
              var drafts = [];
              for (var Id in self.unitNeedToMerge) {
                drafts.push(self.unitNeedToMerge[Id]);
              }
              table.draftValues = drafts;
            }
          })
          .catch(() => {
            self.toastError(MSG_Application_Error, MSG_Error_Validating_Data);
          });
      }
    }
    var drafts = [];
    for (var Id in self.unitNeedToMerge) {
      drafts.push(self.unitNeedToMerge[Id]);
    }
    table.draftValues = drafts;
  }*/
  alreadyExistInDraftsDiffrentId(Id, ProductCode) {
    for (var index in this.unitNeedToMerge) {
      if (
        index !== Id &&
        this.unitNeedToMerge[index].ProductCode === ProductCode
      ) {
        return true;
      }
    }
    return false;
  }
  alreadyExistInDraftsSameId(Id, ProductCode) {
    for (var index in this.unitNeedToMerge) {
      if (
        index === Id &&
        this.unitNeedToMerge[index].ProductCode === ProductCode
      ) {
        return true;
      }
    }
    return false;
  }
  generateMessage(SaveResultWrapper) {
    this.ErrorMessage = "";
    this.InformationMessage = "";
    this.globalErrorMessage = SaveResultWrapper.errorMessage;
    if (this.globalErrorMessage) {
      this.globalErrorMessageBool = true;
    } else {
      this.globalErrorMessageBool = false;
    }
    var ErrorMessage = [];
    var InformationMessage = [];
    var validationWrappersList = SaveResultWrapper.validationWrappersList;
    for (var index in validationWrappersList) {
      var message = validationWrappersList[index];
      if (validationWrappersList[index].isValid) {
        InformationMessage.push(message);
      } else {
        ErrorMessage.push(message);
      }
    }
    if (InformationMessage.length > 0)
      this.InformationMessage = InformationMessage;
    if (ErrorMessage.length > 0)
      this.ErrorMessage = ErrorMessage;
  }
  get colspanUniteNeed() {
    return this.displayedUnitNeedFieldsAPIs.length;
  }
  get colspanProduct() {
    return this.displayedProductFieldsAPIs.length;
  }
  unitNeedInputSubmitHandler(event) {
    if (!event.target.value || (event.target.value && event.which === 13) || (event.target.value && event.which === 9)) {
      var self = this;
      var row = {
        Id: event.target.name,
        ProductCode: event.target.value
      };
      var selector = '[data-id="' + row.Id + '"]';
      var element = this.template.querySelector(selector);
      if (!row.ProductCode) {
        delete this.unitNeedToMerge[row.Id];
      } else if (this.alreadyExistInDraftsDiffrentId(row.Id, row.ProductCode)) {
        delete this.unitNeedToMerge[row.Id];
        this.toastError(
          MSG_Application_Error,
          MSG_Product_Code_Already_Assigned
        );
        if (element) {
          element.value = '';
        }
      } else if (this.alreadyExistInDraftsSameId(row.Id, row.ProductCode)) { } else {
        validateUniteNeedlink({
          uniteNeedId: row.Id,
          productCode: row.ProductCode
        })
          .then(data => {
            var validation = JSON.parse(data);
            if (validation.isValid) {
              self.toastSuccess(validation.status, validation.comment);
              if (row.ProductCode) {
                self.unitNeedToMerge[row.Id] = row;
              }
            } else {
              delete self.unitNeedToMerge[row.Id];
              self.toastError(validation.status, validation.comment);
              if (element) {
                element.value = '';
              }
            }
          })
          .catch(() => {
            self.toastError(MSG_Application_Error, MSG_Error_Validating_Data);
          });
      }
    }
  }
  onBlurUnitNeedInputSubmitHandler(event) {
    var self = this;
    var row = {
      Id: event.target.name,
      ProductCode: event.target.value
    };
    var selector = '[data-id="' + row.Id + '"]';
    var element = this.template.querySelector(selector);
    if (!row.ProductCode) {
      delete this.unitNeedToMerge[row.Id];
    } else if (this.alreadyExistInDraftsDiffrentId(row.Id, row.ProductCode)) {
      delete this.unitNeedToMerge[row.Id];
      this.toastError(
        MSG_Application_Error,
        MSG_Product_Code_Already_Assigned
      );
      if (element) {
        element.value = '';
      }
    } else if (this.alreadyExistInDraftsSameId(row.Id, row.ProductCode)) { } else {
      validateUniteNeedlink({
        uniteNeedId: row.Id,
        productCode: row.ProductCode
      })
        .then(data => {
          var validation = JSON.parse(data);
          if (validation.isValid) {
            self.toastSuccess(validation.status, validation.comment);
            if (row.ProductCode) {
              self.unitNeedToMerge[row.Id] = row;
            }
          } else {
            delete self.unitNeedToMerge[row.Id];
            self.toastError(validation.status, validation.comment);
            if (element) {
              element.value = '';
            }
          }
        })
        .catch(() => {
          self.toastError(MSG_Application_Error, MSG_Error_Validating_Data);
        });
    }
  }
  handleCancel() {
    console.log('cancel');
    this[NavigationMixin.Navigate]({
      type: 'standard__webPage',
      attributes: {
        url: '/lightning/page/home'
      }
    });
    console.log('end cancel');
  }
}
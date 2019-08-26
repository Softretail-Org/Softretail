/* eslint-disable no-alert */
/* eslint-disable vars-on-top */
/* eslint-disable guard-for-in */
/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
 
import { LightningElement, wire, api, track } from "lwc";
const ProductToDetailMap = new Map();
const PageToProductsMap = new Map();
import HeaderData from "@salesforce/apex/MyTestLWCController.HeaderData";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAssPath from "@salesforce/apex/MyTestLWCController.getAssPath";
import importFilteredProducts from "@salesforce/apex/MyTestLWCController.importFilteredProducts";
import SaveSelection from "@salesforce/apex/MyTestLWCController.SaveSelection";
import initRecords from "@salesforce/apex/MyTestLWCController.initRecords";
import getsProductRecords from "@salesforce/apex/MyTestLWCController.getsProductRecords";
import apexSearch from '@salesforce/apex/LookupSearchResult.search';
import { refreshApex } from '@salesforce/apex';
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';
function search(str, search_str) {
  var result = str.search(new RegExp(search_str, "i"));
  if (result >= 0) return true;
  return false;
}
const tablecolumns = [
  {
    label: 'Product Image',
    type: 'ImageCell',
    fieldName: 'id',
    sortable: true,
    fixedWidth: 70,
    typeAttributes: {
      attrA: { fieldName: 'attrA' },
      attrB: { fieldName: 'attrB' },
      ShowIcon: { fieldName: 'ShowIcon' },
    },
},
  { label: 'Name', fieldName: 'Name', type:'Text', sortable: true,
  cellAttributes: { Id: { fieldName: 'status' } } },
  { label: 'Brand', sortable: true,fieldName: 'BrandName', type: 'Text' },
  { label: 'Category',sortable: true, fieldName: 'CategoryName', type: 'Text' },
  { label: 'Parent Element',sortable: true, fieldName: 'ParetnElementName', type: 'Text' },
  { label: 'Product EAN',sortable: true, fieldName: 'ProductEAN', type: 'Text'  },
  
  ];
export default class importProductsLWC extends LightningElement {
  @api recordId = "a041v000011NUgTAAW";
  @api isAuraWrapped = false;
  @api AssPath ;
  @track data;
  @track LoadPage = false;
  @track SelectedCount = 0;
  @track columns;
  @track selectedRows = [];
  @track HeaderTitle ="Test";
  @track HeaderLabel= "test";
  @track firstTime = true;
  @track Loaded;
  @track SelectedProducts;
  @track sortedBy;
  @track sortedDirection = 'desc';
  Selected = [];
  ExistingDetailsId = [];
  ExistingDetailsToDeleteIdList = [];
  wiredProductsData =[];
  wiredDetailsData =[];
  @track SearchFieldValue="";
  ReturnedSearchList = [];
  @track SpinnerRun=false;
  @track InfiniteLoading=true ;
  @track SearchEvent = false;
  @track Loading = false;
  @track offset =0;
  @track Page=0;
  @track StartedLimit = 50;
  @track limit =50;
  @track Difference = this.offset + this.limit;
  @track Total;
  @wire(CurrentPageReference) pageRef;
  
  @wire(getAssPath , {
    recId:'$recordId'
  })
  WireOrgaCode ({data}){
    if (data) {
      this.AssPath = data;
    }
  }

  @wire(initRecords, {
    recId:'$recordId',
    Path: '$AssPath',
    limitSize :'$StartedLimit', 
    Orderby: "Id",
    OrderDir: "ASC"
  })
  ResetData;

  @wire(initRecords, {
    recId:'$recordId',
    Path: '$AssPath',
    limitSize :'$StartedLimit', 
    Orderby: "Id",
    OrderDir: "ASC"
  })
  wiredProducts({ error, data }) {
    HeaderData({
      recordId : this.recordId
      }).then(Headdata => {
 
          Headdata = JSON.parse(Headdata);
          this.HeaderLabel = Headdata.Label;
          this.HeaderTitle = Headdata.LongName
 
      })
      .catch(Headerror => {
          console.log(error);
      });
    this.SetInitialData(error,data);

  }
 


  HandleProductSearch(evt) {
     this.SearchFieldValue = evt.target.value;
    if (!this.SearchFieldValue || evt.which === 13) this.SearchAction(evt,false);
  }
  
  SaveAction(evt) {
    this.SpinnerRun=true;
    this.HandleSelectedRows();
 
    let Removed =[];
    this.wiredDetailsData.forEach( item => {
      if(this.ExistingDetailsToDeleteIdList.includes(item.Product__c)) {
        Removed.push(item.Id);
      }
    }) 
 
    SaveSelection({
      removedAssortmentDetails: JSON.stringify(Removed),
      addedProducts: JSON.stringify(this.Selected),
      assBUId: this.recordId
    })
      .then((result)=> {
        refreshApex(this.ResetData);
        this.EnableButtons(null);
        this.SpinnerRun=false;
        const event = new ShowToastEvent({
          title: 'Save Completed',
          message: 'Products Imported ',
          variant: 'success',
          mode: 'dismissable'
      });
      this.dispatchEvent(event);
      })
      .catch(error => {
        let message =  JSON.stringify(error.body.message);
        this.SpinnerRun=false;
        const event = new ShowToastEvent({
            title: 'Save was Unsuccessfull',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
      });
  }
  handleSearch(event) {
     
    apexSearch(event.detail)
        .then(results => {
          
            this.template.querySelector('c-lookup').setSearchResults(results);
        })
        .catch(error => {
            console.log(error);
        });
}


callProductGetter(concatinate){
 
  getsProductRecords({
    
    recId :'$recordId',
    Path: this.AssPath,
    LimitSize: parseInt(this.limit,10),
    offset:parseInt(this.offset,10),
    SearchTerm:this.SearchFieldValue,
    }).then(data => {
  
        this.FixData(data ,concatinate);
        this.Loading =false;
        this.InfiniteLoading = true;
        this.SpinnerRun=false;
    })
    .catch(error => {
        console.log(error);
    });
}
FixData(data ,concatinate){
  var i=0;
 
 
 
  this.CalculatedSelectedRows = [];
    this.Selected.forEach(item => {
      this.CalculatedSelectedRows.push(item);
    });
    console.log("Existing >>>"+this.ExistingDetailsId);
    this.ExistingDetailsId.forEach( item => {
      
      if(!this.ExistingDetailsToDeleteIdList.includes(item))
      this.CalculatedSelectedRows.push(item);
    })
    console.log("CalculatedSelectedRows >>>"+this.CalculatedSelectedRows);
    console.log('New Existing '+JSON.parse(data.PageAssBUDetails));
    let NewSelected = JSON.parse(data.PageAssBUDetails);
    NewSelected.forEach (item =>{
      if(!this.ExistingDetailsId.includes(item.product__c)) 
        this.ExistingDetailsId.push(item.product__c);
        if(!this.ExistingDetailsToDeleteIdList.includes(item.product__c))
        this.CalculatedSelectedRows.push(item.product__c);
        i++;
      
    })
  this.Total = parseInt(JSON.parse(data.Total),10);
  
  this.updateDifference();
    this.SelectedCount = this.CalculatedSelectedRows.length;
    this.SelectedProducts = this.SelectedCount + ' Products Selcted';
     this.selectedRows = this.CalculatedSelectedRows;
     if (concatinate) {
     this.data = this.data.concat(JSON.parse(data.PageData));
     
    }
     else
     this.data=JSON.parse(data.PageData);
     this.Loaded = 'Loaded '+this.data.length +' of '+this.Total +' Products ';

}

updateDifference(){
  this.Difference = (this.Page+1)*this.limit;
  if (this.Page >= parseInt((this.Total/this.limit),10))
  this.Difference = this.Total;
  this.HandleSelectedRows();
  
}
 
HandleSelectedRows(){
  let Mydata = [];
  this.data.forEach( item => {
    Mydata.push(item.Id);
  })
  let TableSelected = this.template.querySelector('[data-id="ProductTable"]').selectedRows;
  for (let index in Mydata) {
    if (TableSelected.includes(Mydata[index])) {
      if(!this.ExistingDetailsId.includes(Mydata[index])){
        if(!this.Selected.includes(Mydata[index])){
          this.Selected.push(Mydata[index]);
          this.Total++;
      }
    }
      else if (this.ExistingDetailsId.includes(Mydata[index])){
        if(this.ExistingDetailsToDeleteIdList.includes(Mydata[index])) {
          this.ExistingDetailsToDeleteIdList.splice(this.ExistingDetailsToDeleteIdList.indexOf(Mydata[index]),1);
          this.Total++;
        }
      }
    }else {
      if(this.ExistingDetailsId.includes(Mydata[index])) {
          if(!this.ExistingDetailsToDeleteIdList.includes(Mydata[index])){
            this.Total--;
        this.ExistingDetailsToDeleteIdList.push(Mydata[index]);
          }
      }else{
          if(this.Selected.includes(Mydata[index])){
            this.Total--;
            this.Selected.splice(this.Selected.indexOf(Mydata[index]),1);
          }
      }
      
    }
    
  } 
   
}
SearchAction(event ,concatinate) {
      this.Page=0;
      this.offset = 0 ; 
      this.InfiniteLoading=false;
      this.HandleSelectedRows();
      this.callProductGetter(concatinate);
}

loadMoreData(evt){console.log("Loading more :"+this.InfiniteLoading);

  console.log("this.data :"+this.data.length);
  this.InfiniteLoading=false;
  this.Loading=true;
  this.HandleSelectedRows();
  if ((this.data.length < this.Total)){
  
  this.Page++;
  

  console.log(this.Total);
  this.offset = this.Page*this.limit;
  if(this.offset<this.Total){
    
    this.callProductGetter(true);
    
  }
      
}
      else{
        this.Loading =false;
      }
    }
 
  
 importAllFiltered(event){
  this.SpinnerRun=true;
  console.log("Sleected B4 >>>"+ this.Selected);
    let FilteredSelected=[];
  this.data.forEach( item => {
      if (!this.ExistingDetailsId.includes(item.Id)) {
        FilteredSelected.push(item.Id);
      } 
  })
 
  
  importFilteredProducts({
    
    AssBU : this.recordId,
    Path: this.AssPath,
    SearchTerm:this.SearchFieldValue,
    }).then(data => {
      
      refreshApex(this.
      
      Data);
      this.EnableButtons(event);
      this.callProductGetter(false);
      this.spinner=false;
        const evt = new ShowToastEvent({
            title: 'Save Completed',
            message: 'Filtered Products Imported ',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    })
    .catch(error => {
      let message =  JSON.stringify(error.body.message);
      this.spinner=false;
        const evt = new ShowToastEvent({
            title: 'Save was Unsuccessfull',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    });
 
 }
 
connectedCallback() {
  if (this.isAuraWrapped) {
    registerListener('importAllFiltered', this.importAllFiltered, this);
    registerListener('SaveAction', this.SaveAction, this); 
  }
}
 
disconnectedCallback() {
    unregisterAllListeners(this);
}
SetInitialData(error,data){
  this.CalculatedSelectedRows=[];
   if (data) { 
    var i = 0;
    this.Total = 0;
    this.selectedRows = [];
    this.SelectedCount=0;
    this.ExistingDetailsId=[]
    this.ExistingDetailsToDeleteIdList = [];
    this.wiredDetailsData = JSON.parse(data.AssBUDetailsList);
    console.log("Data ASS is >>>>:"+ JSON.stringify(JSON.parse(data.AssBUDetailsList)),null,4);
    console.log("Data is >>>>:"+ JSON.stringify(data,null,4));
    for(let index in this.wiredDetailsData){
      this.SelectedCount++;
      this.ExistingDetailsId.push(this.wiredDetailsData[index].Product__c);
    }

    this.Total = data.totalCount;
     
    this.selectedRows = this.ExistingDetailsId;
    this.Selected = [];
    this.Unselected = [];

     
     this.columns =tablecolumns;
      
     this.wiredProductsData = JSON.parse(data.sobList);
     if(this.firstTime) {
     this.data = this.wiredProductsData;
     this.firstTime = false;
     }
     else{
       let clone = this.data;
       this.selectedRows = this.ExistingDetailsId;
       this.data = clone;
     }
     this.Loaded = 'Loaded '+this.data.length +' of '+this.Total +' Products ';
     this.LoadPage = true;
     this.FireAuraEvent(null);
     
   }else{
     console.log(error);
   }
}
SelectedRowsCounter(evt){
  this.SelectedCount = evt.target.selectedRows.length;
  this.FireAuraEvent(null);
}
FireAuraEvent(evt) {
  this.SelectedProducts = this.SelectedCount + ' Products Selcted';
  const eventName = 'SetText';
  const event = new CustomEvent(eventName, {
      detail: { number: this.SelectedCount }
  });
  this.dispatchEvent(event);
}
EnableButtons(evt) {
  const eventName = 'EnableButtons';
  const event = new CustomEvent(eventName);
  this.dispatchEvent(event);
}
Sorting(evt) { 
  let mydata = [];
  this.data.forEach( item => {
    mydata.push(item);
  })
  console.log("B4 >>>>"+JSON.stringify(this.data[0]));
  //function to return the value stored in the field
  var key =(a) => a[evt.detail.fieldName]; 
  var reverse = this.sortDirection === 'asc' ? 1: -1;
  this.sortDirection = this.sortDirection === 'asc' ? 'desc': 'asc';
  //set sorted data to opportunities attribute
  mydata.sort((a,b) => {
      let valueA = key(a) ? key(a).toLowerCase() : '';
      let valueB = key(b) ? key(b).toLowerCase() : '';
      return reverse * ((valueA > valueB) - (valueB > valueA));
  });
  this.data = mydata;
  console.log("AF >>>>"+JSON.stringify(this.data[0]));
  console.log("fieldname "+evt.detail.fieldName);
  console.log("direction "+this.sortDirection);
}
@track selectedAccountRecord;  

// Event bubbles to grandparent and being handled here - Account  
handlelookupselectaccount(event) {  
 
  this.selectedAccountRecord = event.detail;  
}  
// Event bubbles to grandparent and being handled here - Contact  
get options() {
  return [
      { label: 'New', value: 'new' },
      { label: 'In Progress', value: 'inProgress' },
      { label: 'Finished', value: 'finished' },
  ];
}
handleSuccess(event) {
  this.dispatchEvent(
      new ShowToastEvent({
          title: 'Success',
          message: event.detail.apiName + ' created.',
          variant: 'success',
      }),
  );
}
handleSelectedProduct(evt){
  
  if(evt.detail) {
    this.SearchFieldValue = evt.detail.subtitle.split("•")[1];
  }else {
    this.SearchFieldValue = "";
  }
   console.log("Parent Received >>>"+this.SearchFieldValue );
    this.SearchAction(evt,false);
  
}
handleChange(event) {
  console.log("You selected an account: " + event.detail.value[0]);
}
handleSubmit(event) {
  console.log("Arrived term is>>>>"+event.detail);
  this.SearchFieldValue = event.detail;
  this.SearchAction(event,false);
}
handleReset(evt) {
  this.SearchFieldValue ="";
  this.SearchAction(null,false);
}
}
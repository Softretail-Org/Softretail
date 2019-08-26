import { LightningElement, track, wire } from 'lwc';
import getSelectOptionsCountries from "@salesforce/apex/MassBatchControllerForLightning.getSelectOptionsCountries";
import getSelectOptionsGroupBusinessUnits from "@salesforce/apex/MassBatchControllerForLightning.getSelectOptionsGroupBusinessUnits";
import getSettingsForSections from "@salesforce/apex/MassBatchControllerForLightning.getSettingsForSections";
import getJobs from "@salesforce/apex/MassBatchControllerForLightning.getJobs";
import generateInvoice from "@salesforce/apex/MassBatchControllerForLightning.generateInvoice";
import callCalculateTo from "@salesforce/apex/MassBatchControllerForLightning.callCalculateTo";
import dispatchingBatch from "@salesforce/apex/MassBatchControllerForLightning.dispatchingBatch";
import baseRedistributionBatch from "@salesforce/apex/MassBatchControllerForLightning.baseRedistributionBatch";
import duplicateContractBatch from "@salesforce/apex/MassBatchControllerForLightning.duplicateContractBatch";
import generateGRCRatesBatch from "@salesforce/apex/MassBatchControllerForLightning.generateGRCRatesBatch";
import groupContractScanBatch from "@salesforce/apex/MassBatchControllerForLightning.groupContractScanBatch";
import groupInvoiceScanBatch from "@salesforce/apex/MassBatchControllerForLightning.groupInvoiceScanBatch";
import groupInvoiceSynchroBatch from "@salesforce/apex/MassBatchControllerForLightning.groupInvoiceSynchroBatch";
import groupInvoicePaymentScanBatch from "@salesforce/apex/MassBatchControllerForLightning.groupInvoicePaymentScanBatch";
import groupInvoicePaymentSynchroBatch from "@salesforce/apex/MassBatchControllerForLightning.groupInvoicePaymentSynchroBatch";
import submitCommercialPlanScanContractBatch from "@salesforce/apex/MassBatchControllerForLightning.submitCommercialPlanScanContractBatch";
import submitCommercialPlanScanStatusBatch from "@salesforce/apex/MassBatchControllerForLightning.submitCommercialPlanScanStatusBatch";
import submitCloseSupplierBatch from "@salesforce/apex/MassBatchControllerForLightning.submitCloseSupplierBatch";
import submitLastActiveContractBatch from "@salesforce/apex/MassBatchControllerForLightning.submitLastActiveContractBatch";
import submitSellinToPurchaseBatch from "@salesforce/apex/MassBatchControllerForLightning.submitSellinToPurchaseBatch";
import submitReparentingSellinBatch from "@salesforce/apex/MassBatchControllerForLightning.submitReparentingSellinBatch";
import submitInvoiceReminderBatch from "@salesforce/apex/MassBatchControllerForLightning.submitInvoiceReminderBatch";
import penaltiesScanSynchroBatch from "@salesforce/apex/MassBatchControllerForLightning.penaltiesScanSynchroBatch";
import submitCounterpartiesScanContractBatch from "@salesforce/apex/MassBatchControllerForLightning.submitCounterpartiesScanContractBatch";
import submitCounterpartiesScanStatusBatch from "@salesforce/apex/MassBatchControllerForLightning.submitCounterpartiesScanStatusBatch";
import submitMarketDataCollectionScanBatch from "@salesforce/apex/MassBatchControllerForLightning.submitMarketDataCollectionScanBatch";
import submitMarketDataCollectionSynchroBatch from "@salesforce/apex/MassBatchControllerForLightning.submitMarketDataCollectionSynchroBatch";
import submitGroupRebatePaymentScanBatch from "@salesforce/apex/MassBatchControllerForLightning.submitGroupRebatePaymentScanBatch";
import submitGroupRebatePaymentSynchroBatch from "@salesforce/apex/MassBatchControllerForLightning.submitGroupRebatePaymentSynchroBatch";
import uploadFile from "@salesforce/apex/MassBatchControllerForLightning.uploadFile";
import uploadConditionPenaltiesExcelFile from "@salesforce/apex/MassBatchControllerForLightning.uploadConditionPenaltiesExcelFile";
import getSobjectsLabel from "@salesforce/apex/MassBatchControllerForLightning.getSobjectsLabel";
import getFieldsLabel from "@salesforce/apex/MassBatchControllerForLightning.getFieldsLabel";
import submitGenerateSFPlanning from "@salesforce/apex/MassBatchControllerForLightning.submitGenerateSFPlanning";
import submitUpdateSFPlanning from "@salesforce/apex/MassBatchControllerForLightning.submitUpdateSFPlanning";
import groupContractSynchroBatch from "@salesforce/apex/MassBatchControllerForLightning.groupContractSynchroBatch";
import submitConsolidateAssortmentBatch  from "@salesforce/apex/MassBatchControllerForLightning.submitConsolidateAssortmentBatch";
import { refreshApex } from '@salesforce/apex';
import Nego_Dashboard from "@salesforce/label/c.LBL_Nego_Dashboard";
import Country from "@salesforce/label/c.LBL_Country";
import dateLabel from "@salesforce/label/c.LBL_Date";
import contracts_conditions from "@salesforce/label/c.LBL_Contracts_and_Conditions_Procedures";
import GenerateInvoice from "@salesforce/label/c.LBL_GenerateInvoice";
import Run from "@salesforce/label/c.LBL_Run";
import Calculate_Contracts from "@salesforce/label/c.LBL_Calculate_Contracts";
import Dispatch from "@salesforce/label/c.LBL_Dispatch";
import Dispatching_Based_On_Redistribution_Model from "@salesforce/label/c.LBL_Dispatching_Based_On_Redistribution_Model";
import Contracts_Duplication from "@salesforce/label/c.LBL_Contracts_Duplication";
import Duplicate_Contract from "@salesforce/label/c.LBL_Duplicate_Contract";
import Last_Active_Contract_Procedure from "@salesforce/label/c.LBL_Last_Active_Contract_Procedure";
import GRC_Contract_Rates from "@salesforce/label/c.LBL_GRC_Contract_Rates";
import Last_Active_Contract from "@salesforce/label/c.LBL_Last_Active_Contract";
import Calculate_Rates from "@salesforce/label/c.LBL_Calculate_Rates";
import Group_Scan_and_Synchro from "@salesforce/label/c.LBL_Group_Scan_and_Synchro";
import Contract_Group from "@salesforce/label/c.LBL_Contract_Group";
import Scan from "@salesforce/label/c.LBL_Scan";
import Synchro from "@salesforce/label/c.LBL_Synchro";
import Invoice_Group from "@salesforce/label/c.LBL_Invoice_Group";
import Invoice_Payment_Group from "@salesforce/label/c.LBL_Invoice_Payment_Group";
import Rebate_Payment_Group from "@salesforce/label/c.LBL_Rebate_Payment_Group";
import Scan_Update_Contracts from "@salesforce/label/c.LBL_Scan_Update_Contracts";
import Scan_Update_Extraction_Status from "@salesforce/label/c.LBL_Scan_Update_Extraction_Status";
import Sell_In_Procedure from "@salesforce/label/c.LBL_Sell_In_Procedure";
import Consolidate_Sell_in_Flow_Purchase_Flow_PG from "@salesforce/label/c.LBL_Consolidate_Sell_in_Flow_Purchase_Flow_PG";
import Re_Scan_Sell_in_Flow from "@salesforce/label/c.LBL_Re_Scan_Sell_in_Flow";
import Invoice_Reminder from "@salesforce/label/c.LBL_Invoice_Reminder";
import Mass_Distribution from "@salesforce/label/c.LBL_Mass_Distribution";
import Batches from "@salesforce/label/c.LBL_Batches";
import Close_Supplier from "@salesforce/label/c.LBL_Close_Supplier";
import Group_BU from "@salesforce/label/c.LBL_Group_BU";
import uploadLabel from "@salesforce/label/c.LBL_Upload";
import procedure from "@salesforce/label/c.LBL_Procedure";
import scanSynchro from "@salesforce/label/c.LBL_Scan_Synchro";
import marketDataCollection from "@salesforce/label/c.LBL_Market_Data_Collection";
import GenerateSFPlanningLabel from "@salesforce/label/c.LBL_GenerateSFPlanning";
import UpdateSFPlanningLabel from "@salesforce/label/c.LBL_UpdateSFPlanning";
import Scan_Update_Status from "@salesforce/label/c.LBL_Scan_Update_Status";
import Latest_Active_Jobs from "@salesforce/label/c.LBL_Latest_Active_Jobs";
import Level_of_reminder_managed from "@salesforce/label/c.LBL_Level_of_reminder_managed";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class Mass_Batch_Form extends LightningElement {
  @track error;
  @track SectionAssortmentSFPlanning;
  @track SectionBatches;
  @track SectionCallingWebServices;
  @track SectionContractCounterpartyDetail;
  @track SectionContractDuplication;
  @track SectionContractRates;
  @track SectionContractTOProcedures;
  @track SectionGroupScanAndSynchro;
  @track SectionInvoiceReminder;
  @track SectionLastActiveContractProcedure;
  @track SectionMarketDataCollection;
  @track SectionMassDistribution;
  @track SectionPenaltiesProcedure;
  @track SectionPromoDetailProcedure;
  @track SectionSellInProcedure;
  @track remindersval = [0, 1, 2, 3];
  @track separatorVal = [',', ';', '|', ':'];
  @track todayDate;
  @track listOfJobs;
  @track counter = 0;
  //value of country,date:
  @track countrySelected;
  @track dateSelected;
  @track lastActiveContractVal = false;
  @track buSelectedVal;
  @track reminderSelected = 0;
  @track isYearly = false;
  @track contentFileMass;
  @track fileNameMass = 'No File Selected';
  @track contentFilePenalite;
  @track fileNamePenalite = 'No File Selected';
  @track selectedSeparator = ',';
  @track mapObjectsLabel = [];
  //objects label:
  @track commercialPlanDetail;
  @track contrDiscCounter;
  @track assortSFPlan;
  @track supplyPenalty;
  @track assDetail;
  //fileds label of asyncjob:
  @track labelcreateddate;
  @track labeljobtype;
  @track labelstatus;
  @track labeltotaljobitems;
  @track labeljobitemsprocessed;
  @track labelnumberoferrors;
  @track labelcreatedbyid;
  @track labelcompleteddate;
  @track apexClassName;
  @track apexJobId;
  @track logLabel;
  @track loading;
  @track toggleIconName = 'utility:chevrondown';
  @track displayed = 'display:block;';
  connectedCallback() {
    var monthNames = [
      "Jan", "Feb", "Mar",
      "Apr", "May", "Jun", "Jul",
      "Aug", "Sep", "Oct",
      "Nov", "Dec"
    ];
    var date = new Date();
    var day = date.getDate();
    var monthIndex = date.getMonth();
    var year = date.getFullYear();
    var k;
    this.todayDate = day + ' ' + monthNames[monthIndex] + ' ' + year;
    this.dateSelected = year + '-' + (monthIndex + 1) + '-' + day;
    //get objects label :
    getSobjectsLabel().then(data => {
      for (k in data) {
        this.mapObjectsLabel.push({ 'key': k, 'value': data[k] });
        switch (k) {
          case "Commercial_Plan_Detail__c": this.commercialPlanDetail = data[k];
            break;
          case "Contract_discount_counterparty_detail__c": this.contrDiscCounter = data[k];
            break;
          case "Assortment_SF_Planning__c": this.assortSFPlan = data[k];
            break;
          case "Supply_Penalty__c": this.supplyPenalty = data[k];
            break;
          case "Log__c": this.logLabel = data[k];
            break;
            case "Assortment_Detail__c" : this.assDetail = data[k];
            break;
          default: break;
        }
      }
    }).
      catch(error => {
        console.log("Error " + error);
      });
    //get fields labels of AsyncJob:
    getFieldsLabel({ objectName: 'AsyncApexJob' }).then(data => {
      var t;
      for (t in data) {
        switch (t) {
          case 'createddate': this.labelcreateddate = data[t];
            break;
          case 'jobtype': this.labeljobtype = data[t];
            break;
          case 'status': this.labelstatus = data[t];
            break;
          case 'totaljobitems': this.labeltotaljobitems = data[t];
            break;
          case 'jobitemsprocessed': this.labeljobitemsprocessed = data[t];
            break;
          case 'numberoferrors': this.labelnumberoferrors = data[t];
            break;
          case 'createdbyid': this.labelcreatedbyid = data[t];
            break;
          case 'completeddate': this.labelcompleteddate = data[t];
            break;
          case 'id': this.apexJobId = data[t];
            break;
          default: break;
        }
      }
    }).
      catch(error => {
        console.log("Error " + error);
      });
    //get field label of apexClass:
    getFieldsLabel({ objectName: 'ApexClass' }).then(data => {
      var t;
      for (t in data) {
        switch (t) {
          case 'name': this.apexClassName = data[t];
            break;
          default: break;
        }
      }
    }).
      catch(error => {
        console.log("Error " + error);
      });
    this.loading = true;
  }

  renderedCallback() {
    this.template.querySelectorAll('[data-id="statusCell"]').forEach(element => {
      if (element.textContent !== 'Completed') {
        console.log('call refresh first time');
        refreshApex(this.jobList);
        setTimeout(() => {
          console.log('wait 3 sec and call refresh');
          refreshApex(this.jobList);
        }, 3000);
      }
    });
  }

  label = {
    Nego_Dashboard,
    Country,
    dateLabel,
    contracts_conditions,
    GenerateInvoice,
    Run,
    Calculate_Contracts,
    Dispatch,
    Dispatching_Based_On_Redistribution_Model,
    Contracts_Duplication,
    Duplicate_Contract,
    Last_Active_Contract_Procedure,
    GRC_Contract_Rates,
    Last_Active_Contract,
    Calculate_Rates,
    Group_Scan_and_Synchro,
    Contract_Group,
    Scan,
    Synchro,
    Invoice_Group,
    Invoice_Payment_Group,
    Rebate_Payment_Group,
    Scan_Update_Contracts,
    Scan_Update_Extraction_Status,
    Sell_In_Procedure,
    Consolidate_Sell_in_Flow_Purchase_Flow_PG,
    Re_Scan_Sell_in_Flow,
    Invoice_Reminder,
    Mass_Distribution,
    Batches,
    Close_Supplier,
    Group_BU,
    uploadLabel,
    procedure,
    scanSynchro,
    marketDataCollection,
    GenerateSFPlanningLabel,
    UpdateSFPlanningLabel,
    Scan_Update_Status,
    Latest_Active_Jobs,
    Level_of_reminder_managed
  };

  @wire(getJobs) jobList;
  @wire(getSelectOptionsCountries) countryList;
  @wire(getSelectOptionsGroupBusinessUnits) buList;
  @wire(getSettingsForSections) settingsList(result) {
    var sectionVal = "";
    var k;
    var consts;
    if (result.data) {
      consts = result.data;
      for (k in consts) {
        sectionVal = consts[k].split('=')[0];
        switch (sectionVal) {
          case "MBF_Section_AssortmentSFPlanning":
            this.SectionAssortmentSFPlanning = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_Batches':
            this.SectionBatches = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_CallingWebServices':
            this.SectionCallingWebServices = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_ContractCounterpartyDetail':
            this.SectionContractCounterpartyDetail = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_ContractDuplication':
            this.SectionContractDuplication = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_ContractRates':
            this.SectionContractRates = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_ContractTOProcedures':
            this.SectionContractTOProcedures = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_GroupScanAndSynchro':
            this.SectionGroupScanAndSynchro = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_InvoiceReminder':
            this.SectionInvoiceReminder = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_LastActiveContractProcedure':
            this.SectionLastActiveContractProcedure = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_MarketDataCollection':
            this.SectionMarketDataCollection = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_MassDistribution':
            this.SectionMassDistribution = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_PenaltiesProcedure':
            this.SectionPenaltiesProcedure = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_PromoDetailProcedure':
            this.SectionPromoDetailProcedure = consts[k].split('=')[1] === "true";
            break;
          case 'MBF_Section_SellInProcedure':
            this.SectionSellInProcedure = consts[k].split('=')[1] === "true";
            break;
          default: break;
        }
      }
    }
    this.loading = false;
  }

  //get country options:
  get countryOptions() {
    return this.countryList.data;
  }

  //get bu options:
  get buOptions() {
    return this.buList.data;
  }

  getlastJobs() {
    return refreshApex(this.jobList);
  }

  //handle onchange country:
  changevalue(evt) {
    console.log("country changed " + evt.target.value);
    this.countrySelected = evt.target.value;
  }

  //handle change date:
  dateChange(evt) {
    console.log("date changed " + evt.target.value);
    this.dateSelected = evt.target.value;
  }

  //handle change bu:
  changevalueBu(evt) {
    console.log("bu changed " + evt.target.value);
    this.buSelectedVal = evt.target.value;
  }

  //handle last active contract:
  onCheck(evt) {
    console.log("before changin checkbox :" + this.lastActiveContractVal);
    this.lastActiveContractVal = evt.target.checked;
    console.log("after changing checkbox :" + this.lastActiveContractVal);

  }

  //handle change reminder:
  changevalueReminder(evt) {
    this.reminderSelected = evt.target.value;
    console.log('reminder changed' + this.reminderSelected);
  }

  //handle change separator:
  changeSeparator(evt) {
    this.selectedSeparator = evt.target.value;
    console.log('separator changed' + this.selectedSeparator);
  }

  expandDiv() {
    if (this.toggleIconName === 'utility:chevrondown') {
      this.toggleIconName = 'utility:chevronright';
      this.displayed = 'slds-hide';
    }
    else {
      this.toggleIconName = 'utility:chevrondown';
      this.displayed = 'slds-show slds-theme--default';
    }
  }

  //handle file upload:
  handleFileChange(event) {
    var file = event.target.files[0];
    if (file) {
      new Promise(function (resolve, reject) {
        var reader = new FileReader();
        reader.onload = function (evt) {
          resolve(evt.target.result);
        };
        reader.readAsText(file);
        reader.onerror = reject;
      })
        .then(result => {
          this.contentFileMass = result;
          var csvPattern = (file["name"]).match(/[^\\/]+\.csv/);
          if (csvPattern !== null) {
            this.fileNameMass = file["name"];
          }
          else {
            const eventTest = new ShowToastEvent({
              title: 'error',
              message: 'you must choose .csv format',
              variant: 'error',
              mode: 'dismissable'
            });
            this.dispatchEvent(eventTest);
          }
        })
        .catch(function (err) {
          console.log(err)
        });
    }
  }

  handleFileChangeSeparator(event) {
    var file = event.target.files[0];
    var csvPattern;
    if (file) {
      new Promise(function (resolve, reject) {
        var reader = new FileReader();
        reader.onload = function (evt) {
          resolve(evt.target.result);
        };
        reader.readAsText(file);
        reader.onerror = reject;
      })
        .then(result => {
          this.contentFilePenalite = result;
          csvPattern = (file["name"]).match(/[^\\/]+\.csv/);
          if (csvPattern !== null) {
            this.fileNamePenalite = file["name"];
          }
          else {
            const eventTest = new ShowToastEvent({
              title: 'error',
              message: 'you must choose .csv format',
              variant: 'error',
              mode: 'dismissable'
            });
            this.dispatchEvent(eventTest);
          }
        })
        .catch(function (err) {
          console.log(err)
        });
    }
  }

  //handle change radio:
  changeToYearly() {
    this.isYearly = true;
    console.log('is yearly' + this.isYearly);
  }

  changeToMonthly() {
    this.isYearly = false;
    console.log('is yearly' + this.isYearly);
  }

  upload() {
    if (this.contentFileMass) {
      uploadFile({ id: this.countrySelected, fileuploaded: this.contentFileMass, isYearlyDistribution: this.isYearly, nameFile: this.fileNameMass, d: this.dateSelected }).then(result => {
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
        setTimeout(() => {
          refreshApex(this.jobList);
        }, 3000);
      })
        .catch(error => {
          this.error = error;
          console.log('error   ' + this.error);
        });
    }
  }

  ConditionPenaltiesExcelFile() {
    if (this.contentFilePenalite) {
      uploadConditionPenaltiesExcelFile({ fileName: this.fileNamePenalite, file: this.contentFilePenalite, selectedSeperator: this.selectedSeparator }).then(result => {
        if (result === '1') {
          const eventTest = new ShowToastEvent({
            title: 'success',
            message: 'batch Run Successfully',
            variant: 'success',
            mode: 'dismissable'
          });
          this.dispatchEvent(eventTest);
          refreshApex(this.jobList);
          setTimeout(() => {
            refreshApex(this.jobList);
          }, 3000);
        }
        else {
          const eventTest = new ShowToastEvent({
            title: 'error',
            message: result,
            variant: 'error',
            mode: 'dismissable'
          });
          this.dispatchEvent(eventTest);
        }
      })
        .catch(error => {
          this.error = error;
          console.log('error   ' + this.error.body.message);
          const eventTest = new ShowToastEvent({
            title: 'error',
            message: this.error.body.message,
            variant: 'error',
            mode: 'dismissable'
          });
          this.dispatchEvent(eventTest);
        });
    }
  }

  //run generate invoice:
  run() {
    if (this.countrySelected) {
      generateInvoice({ c: this.countrySelected, d: this.dateSelected }).then(response => {
        console.log('Invoice generate ' + response);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;
          console.log('error ' + this.error);
        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  CalculateTo() {
    if (this.countrySelected) {
      callCalculateTo({ id: this.countrySelected, d: this.dateSelected }).then(result => {
        console.log('calculate to ' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;
        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  dispatching() {
    if (this.countrySelected) {
      dispatchingBatch({ id: this.countrySelected, d: this.dateSelected }).then(result => {
        console.log('dispatching' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;
        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  baseRedistribution() {
    baseRedistributionBatch({ d: this.dateSelected }).then(result => {
      console.log('base redistribution ' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;

      });
  }

  duplicateContract() {
    if (this.countrySelected) {
      duplicateContractBatch({ id: this.countrySelected, d: this.dateSelected }).then(result => {
        console.log('duplicate contract' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;

        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  generateCRCRate() {
    if (this.countrySelected) {
      generateGRCRatesBatch({ id: this.countrySelected, lastActiveContract: this.lastActiveContractVal, d: this.dateSelected }).then(result => {
        console.log('generate crc' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;

        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  groupContractScan() {
    if (this.buSelectedVal) {
      groupContractScanBatch({ bu: this.buSelectedVal }).then(result => {
        console.log('group contract scan' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;

        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a Group Bu',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  groupContractSynchr() {
    if (this.buSelectedVal) {
      groupContractSynchroBatch({ bu: this.buSelectedVal }).then(result => {
        console.log('group contract synchro' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;

        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a Group BU',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  groupInvoiceScan() {
    groupInvoiceScanBatch({ d: this.dateSelected }).then(result => {
      console.log('group invoice scan' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;

      });
  }

  groupInvoiceSynchr() {
    groupInvoiceSynchroBatch().then(result => {
      console.log('group invoice synchro' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;

      });
  }

  groupInvoicePayScan() {
    groupInvoicePaymentScanBatch().then(result => {
      console.log('group invoice payment scan' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;

      });
  }

  groupInvoicePaySynchr() {
    groupInvoicePaymentSynchroBatch().then(result => {
      console.log('group invoice payment synchro' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;

      });
  }

  groupRebatePayScan() {
    submitGroupRebatePaymentScanBatch({ d: this.dateSelected }).then(result => {
      console.log('group rebate payment scan' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;

      });
  }

  groupRebatePaySynchr() {
    submitGroupRebatePaymentSynchroBatch().then(result => {
      console.log('group rebate payment synchro' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;

      });
  }

  commercialPlanScanContract() {
    if (this.countrySelected) {
      submitCommercialPlanScanContractBatch({ id: this.countrySelected, d: this.dateSelected }).then(result => {
        console.log('commercial plan scan contract' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;

        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  commercialPlanScanStatus() {
    if (this.countrySelected) {
      submitCommercialPlanScanStatusBatch({ id: this.countrySelected, d: this.dateSelected }).then(result => {
        console.log('commercial plan scan status' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;

        });
    }
  }

  closeSuppBatch() {
    submitCloseSupplierBatch().then(result => {
      console.log('close supplier' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;

      });
  }

  lastActiveContract() {
    if (this.countrySelected) {
      submitLastActiveContractBatch({ id: this.countrySelected }).then(result => {
        console.log('last active contract' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;
        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  sellinToPurchase() {
    if (this.countrySelected) {
      submitSellinToPurchaseBatch({ id: this.countrySelected, d: this.dateSelected }).then(result => {
        console.log('sellin to purchase' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;
        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  reparentingSellin() {
    if (this.countrySelected) {
      submitReparentingSellinBatch({ id: this.countrySelected, d: this.dateSelected }).then(result => {
        console.log('reparenting sellin' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;
        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  invoiceReminder() {
    submitInvoiceReminderBatch({ selectedReminderLevel: parseInt(this.reminderSelected) }).then(result => {
      console.log('invoice reminder' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;
      });
  }

  penaltyScanSynchr() {
    penaltiesScanSynchroBatch().then(result => {
      console.log('penalty scan synchr' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;
      });
  }

  CloseSupplierBatch() {
    submitCloseSupplierBatch().then(result => {
      console.log('close supplier' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;
      });
  }

  CounterpartiesScanContractBatch() {
    if (this.countrySelected) {
      submitCounterpartiesScanContractBatch({ id: this.countrySelected, d: this.dateSelected }).then(result => {
        console.log('counter party scan contract' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;
        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  CounterpartiesScanStatusBatch() {
    if (this.countrySelected) {
      submitCounterpartiesScanStatusBatch({ id: this.countrySelected, d: this.dateSelected }).then(result => {
        console.log('counter party scan status' + result);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;
        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  MarketDataCollectionScanBatch() {
    submitMarketDataCollectionScanBatch({ d: this.dateSelected }).then(result => {
      console.log('market data collection scan' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;
      });
  }

  MarketDataCollectionSynchroBatch() {
    submitMarketDataCollectionSynchroBatch({ d: this.dateSelected }).then(result => {
      console.log('market data collection synchro' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;
      });
  }
  ConsolidateAssortmentBatch() {
    if (this.countrySelected) {
      submitConsolidateAssortmentBatch({ id: this.countrySelected, d: this.dateSelected }).then(response => {
        console.log('consolidate assortment ' + response);
        const eventTest = new ShowToastEvent({
          title: 'success',
          message: 'Batch Run Successfully',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(eventTest);
        refreshApex(this.jobList);
      })
        .catch(error => {
          this.error = error;
          console.log('error ' + this.error);
        });
    }
    else {
      const eventTest = new ShowToastEvent({
        title: 'error',
        message: 'you must enter a country',
        variant: 'error',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
    }
  }

  GenerateSFPlanning() {
    submitGenerateSFPlanning().then(result => {
      console.log('generate sf planning' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;
      });
  }
  
  UpdateSFPlanning() {
    submitUpdateSFPlanning({ d: this.dateSelected }).then(result => {
      console.log('update sf planning' + result);
      const eventTest = new ShowToastEvent({
        title: 'success',
        message: 'Batch Run Successfully',
        variant: 'success',
        mode: 'dismissable'
      });
      this.dispatchEvent(eventTest);
      refreshApex(this.jobList);
    })
      .catch(error => {
        this.error = error;
      });
  }
}
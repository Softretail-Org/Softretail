/* eslint-disable no-console */
/* eslint-disable no-unused-vars */
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/** SampleLookupController.search() Apex method */
import apexSearch from '@salesforce/apex/SampleLookupController.searchSOSL';

export default class lookupHolder extends LightningElement {
    
    // Use alerts instead of toast to notify user
    @api notifyViaAlerts = false;
    @api path;
    @track isMultiEntry = false;
    @track initialSelection ;
    @track errors = [];
    searchTerm;
     
    handleLookupTypeChange(event) {
        this.initialSelection = [];
        this.errors = [];
        this.isMultiEntry = true;
    }

    handleSearch(event) {
        /*apexSearch(event.detail)
            .then(results => {
                this.template.querySelector('c-lookup').setSearchResults(results);
            })
            .catch(error => {
                this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
                // eslint-disable-next-line no-console
                console.error('Lookup error', JSON.stringify(error));
                this.errors = [error];
            });*/
            apexSearch(event.detail)
            .then(results => {
                this.template.querySelector('c-lookup-component').setSearchResults(results);
            })
            .catch(error => {
                this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
                // eslint-disable-next-line no-console
                console.error('Lookup error', JSON.stringify(error));
                this.errors = [error];
            });
    }

    handleSelectionChange(evt) {
        let Event = new CustomEvent("selectionchange", {
            detail : evt.detail
           });
           this.dispatchEvent(Event);
        this.errors = [];
    }
    handleChangedTerm(Event) {
        console.log("term is>>>"+Event.detail);
        this.searchTerm=Event.detail;
    }
    handleSubmit(evt) {
         console.log("im in");
        let Event = new CustomEvent("submit", {
            detail : this.searchTerm
           });
           this.dispatchEvent(Event);
        
    }

    checkForErrors() {
        const selection = this.template.querySelector('c-lookup-component').getSelection();
        if (selection.length === 0) {
            this.errors = [
                { message: 'You must make a selection before submitting!' },
                { message: 'Please make a selection and try again.' }
            ];
        } else {
            this.errors = [];
        }
    }
    notifyUser(title, message, variant) {
        if (this.notifyViaAlerts){
            // Notify via alert
            // eslint-disable-next-line no-alert
            alert(`${title}\n${message}`);
        } else {
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
        }
    }
    handleReset(evt) {
        let Event = new CustomEvent("reset");
           this.dispatchEvent(Event);
    }

 
}
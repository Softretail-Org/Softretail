/* eslint-disable no-unused-vars */
/* eslint-disable no-console */
/* datatableDeleteRowBtn.js */
//--------------------------------
//this is an edit on master !!!
//--------------------------------
import { LightningElement, api } from 'lwc';
// Accessibility module
import { baseNavigation } from 'lightning/datatableKeyboardMixins';
// For the render() method
import template from './datatableCell.html';

// export default class DatatableDeleteRowBtn extends baseNavigation(LightningElement) {
export default class DatatableDeleteRowBtn extends LightningElement {
    @api rowId;
    @api attrA;
    @api attrB;
    @api ShowIcon;
    // Required for mixins
    render() {
        return template;
    }
    
}
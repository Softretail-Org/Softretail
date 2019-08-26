/* myDatatable.js */
import LightningDatatable from 'lightning/datatable';
import Cell from './Cell.html';

export default class MyDatatable extends LightningDatatable {
   static customTypes = {
       ImageCell: {
           template: Cell,
           // Provide template data here if needed
           typeAttributes: ['attrA', 'attrB','ShowIcon'],
       }
      //more custom types here
   };
}
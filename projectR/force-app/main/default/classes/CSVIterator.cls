global with sharing class CSVIterator implements Iterator<String>, Iterable<String> {
	
	private String fileData;
   	private String introValue;
   	
   	public CSVIterator(String fileData, String introValue) {
  		this.fileData = fileData;
      	this.introValue = introValue;
   	}
   	
   	global Boolean hasNext() {
  		return this.fileData.length() > 1 ? true : false;
   	}
   	
    global String next() {
        try {
            String row = this.fileData.subString(0, this.fileData.indexOf(this.introValue));
            this.fileData = this.fileData.subString(this.fileData.indexOf(this.introValue) + this.introValue.length(), this.fileData.length());
            return row;
        } catch (Exception ex) {
            this.fileData = '';
            return '';
        }
    }
    
   	global Iterator<String> Iterator() {
  		return this;
   	}
}
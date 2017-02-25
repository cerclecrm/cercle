<template>
<input  v-model="contact[field]" v-on:blur="saveEdit()" type="text" :placeholder="field" style="border:0px solid grey;width:100%;line-height:30px;height:30px;" >
</template>

<script>
export default {
  props: ['contact', 'field'],
  methods: {
    saveEdit: function(){
    	var url = '/api/v2/contact/' + this.contact.id;
    	var params = {};
    	params["contact["+this.field+"]"] = this.contact[this.field];
    	data: params,
      $.ajax( url , {
          method: 'PUT',
          data: params,
          complete: function(xhr, status){
            return true;
          }
        });
    }
  }
}
</script>

<style lang="sass">
  input:focus {
    outline-width: 0;
  }
  textarea{
    resize: none;
  }
</style>
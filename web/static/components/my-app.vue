<template>
  <div class="my-app">
    <div style="max-width:800px;margin: 0px auto;"  >
      <!-- Main content -->
      <section class="content" style="margin-top:20px;">
        <div class="row">
          <div class="col-md-6">
            <!-- Profile Image -->
            <div class="box box-primary">
              <div class="box-body box-profile">
                <div class="box-tools pull-right">
                  <button type="button" class="btn btn-box-tool" id="edit_contact_options" ><i class="fa fa-fw fa-angle-down"></i></button>
                </div>
                <h3 class="profile-username" style="margin-right:30px;">
                   <inline-edit v-bind:contact="contact" field="name"></inline-edit>
                </h3>
                <ul class="list-group list-group-unbordered" style="margin-bottom:5px;">
                  <li class="list-group-item" style="padding-bottom:4px;">
                    <inline-edit v-bind:contact="contact" field="job_title"></inline-edit>
                  </li>
                  <li class="list-group-item" style="padding-bottom:4px;">
                    <inline-edit v-bind:contact="contact" field="email"></inline-edit>
                  </li>
                  <li class="list-group-item" style="padding-bottom:4px;">
                    <inline-edit v-bind:contact="contact" field="phone"></inline-edit>
                  </li>
                  <li class="list-group-item" style="padding-bottom:4px;">
                    <div style="margin-top:5px;">
                    <a id="add_tags" href ="javascript:void(0);" style="font-weight:bold;display:inline-block;padding:3px;border-radius:5px;margin-right:7px;color:grey;">+ Add ...</a>
                  </div>
                </li>
              </ul>
                <inline-edit v-bind:contact="contact" field="description"></inline-edit>
            </div><!-- /.box-body -->
          </div><!-- /.box -->
        </div>
        <div class="col-md-6">
          <div class="box" id="with_organization" style="display:;">
            <div class="box-body box-profile">
              <div class="box-tools pull-right">
                  <button type="button" class="btn btn-box-tool" id="edit_contact_options" ><i class="fa fa-fw fa-angle-down"></i></button>
                </div>
              <h3 class="profile-username"><span class='inline-editable' data-type='PUT' data-param-name="organization[name]" data-inline-editurl="/api/v2/organizations/">ORGANIZATION NAME</span></h3>
              <ul class="list-group list-group-unbordered" style="margin-bottom:5px;">
                <li class="list-group-item" style="padding-bottom:4px;">
                  <input type="text" placeholder="Website" style="border:0px solid grey;width:100%;line-height:30px;" />
                </li>
              </ul>
             <input type="text" placeholder="Note" style="border:0px solid grey;width:100%;line-height:30px;" />
            
            </div><!-- /.box-body -->
          </div><!-- /.box -->
          <div class="box" id="without_organization" style="display:;">
            <div class="box-body box-profile" style="text-align:center;">
              <a href="#sd" style="font-size:16px;" id="change_company_modal">+Add a company</a>
            </div><!-- /.box-body -->
          </div><!-- /.box -->
        </div><!-- /.col -->
      </div>
      <div class="row">
        <div class="col-md-12">
          <div class="post" style="background-color:white;box-shadow: 0 1px 1px rgba(0,0,0,0.1);border-radius: 3px;padding:20px;margin-bottom:10px;">
            <button type="button" class="btn btn-danger pull-right" style="margin-top:10px;" id="opportunity_lost" >LOST</button>
            <button type="button" class="btn btn-success pull-right" style="margin-top:10px;margin-right:10px;" id="opportunity_win" >WIN</button>

            <div style="" id="change_status">
              <span style="font-size:24px;color:rgb(150,150,150);"> <i class="fa fa-rocket" style="color:#d8d8d8;"></i> Part of
                <span style="color:rgb(102,102,102);" class='inline-editable' data-type='PUT' data-param-name="opportunity[name]" data-inline-editurl="/api/v2/opportunity/">OPPOR NAME</span>
              </span>
              <Br />
              <Br />
              <div style="margin-right:20px;margin-bottom:10px;">
                Managed by:


              </div>
              Status:
              <Br />
              <Br />
              Contacts Involved: 
              <a id="add_contact_to_opportunity" href ="javascript:void(0);" style="font-weight:bold;display:inline-block;padding:3px;border-radius:5px;margin-right:7px;color:grey;">+ Add ...</a>
            </div>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-md-12">
          <div class="post" style="background-color:white;box-shadow: 0 1px 1px rgba(0,0,0,0.1);border-radius: 3px;">
            <!-- /.user-block -->
            <div style="padding:15px;">
              <form id="contact-form" >
                <h3 style="margin-top:0px;border-bottom:0px solid #d8d8d8;">
                  <i class="fa fa-fw fa-check-square-o" style="color:#d8d8d8;"></i> To-Do
                </h3>
                <div id="tasks" style="padding:15px;">
  
                </div>
                <div style="padding-left:15px;">
                  <a style="letter-spacing: 1px;color:grey;font-weight:bold;" id="activity_add" href="javascript:void(0);" >Schedule a  Task...</a>
                </div>
                <Br />
                <Br />
                <h3 style="margin-top:0px;border-bottom:0px solid #d8d8d8;">
                  <i class="fa fa-fw fa-comments-o" style="color:#d8d8d8;"></i>
                  Comment
                </h3>
                <input type="hidden" name="timeline_event[event_name]" value="comment">
                <Br />
                <div style="margin-bottom:0px;">
                  <img class="img-circle img-bordered-sm" src="" alt="user image" style="width:40px;float:left;">
                  <div style="margin-left:50px;margin-right:10px;">
                    <textarea class="form-control" name="timeline_event[content]" id="inputExperience" placeholder="Write a comment.."  style="height:70px;"></textarea>
                    <br />
                    <input type="submit" value='Send' class="btn btn-primary" id="submit_timeline_event" /> 
                  </div>
                </div>

              </form>
            </div>
          </div>
          <div id="timeline_events">
          </div>
          </div><!-- /.col -->
        </div>
      </section>
    </div>
  </div>
</template>

<script>
import {Socket, Presence} from "phoenix"
import InlineEdit from "./inline-edit.vue"
export default {
  data() {
    return {
      contact_id: null,
      socket: null,
      channel: null,
      contact: {id: null, name: "", phone:"", email:"", job_title:"" }
    }
  },
  components: {
    'inline-edit': InlineEdit
  },
  methods: {
    connectToSocket() {
      this.contact_id = $("#meta_data").data("contact_id");
      this.socket = new Socket("/socket", {params: {token: window.userToken}});
      this.socket.connect();
      this.channel = this.socket.channel("contacts:" + this.contact_id, {});
      this.channel.join()
        .receive("ok", resp => {  
          console.log("Join OK", resp);
          this.channel.push("load_state");
        })
        .receive("error", resp => { console.log("Unable to join", resp) });
      this.channel.on('state', payload => {
        this.contact = payload;
      });
    }
  },
  mounted(){
    this.connectToSocket();
  }
}
</script>

<style lang="sass">
  .my-app {
    margin-left: auto;
    margin-right: auto;
    width: 800px;

    h1 {
      text-align: center;
    }
  }
</style>
<template>
  <div class="col-md-12 opportunity-block">
    <div class="post" v-if="item">
    <div class="pull-right">
      <button type="button" class="btn btn-primary pull-right browse" v-on:click="browse">BROWSE</button>
      <br />
      <button type="button" class="btn btn-default archive " v-on:click="archiveOpportunity">ARCHIVE</button>
    </div>
      <div style="" id="change_status">
        <span style="font-size:24px;"> <i class="fa fa-rocket" style="color:#d8d8d8;"></i>
          <span data-placeholder="Project Name" style="color:rgb(99,99,99);font-weight:bold;">
            In {{board.name}}
            <Br />
            <inline-edit v-model="item.name" v-on:input="updateOpportunity" placeholder="Card Name" style="width:500px;margin-left:25px;color:grey;"></inline-edit>
          </span>
        </span>
        <br />
        <br />
        <div class="managers">
          Managed by:
          <select v-model.number="item.user_id"  v-on:change="updateOpportunity">
            <option v-for="user in company_users" :value.number="user.id">{{user.user_name}}</option>
          </select>
          &nbsp;&nbsp;
          Status:
          <select v-model="item.board_column_id" v-on:change="updateOpportunity">
             <option v-for="board_column in boardColumns" :value.number="board_column.id">{{board_column.name}}</option>
          </select>
        </div>
        Contacts Involved:
        <a v-for="o_contact in opportunityContacts" :href="'/contact/'+o_contact.id" class="o_contact">{{o_contact.name}}</a>
        <modal title="What is his name?" large :show.sync="openContactModal">
            <div slot="modal-body" class="modal-body">
            <input class="form-control" v-model="NewContactName" type="text" placeholder="Name of the Contact">
            </div>
            <div slot="modal-footer" class="modal-footer">
             <button type="button" class="btn btn-success" v-on:click="addContact">Add Contact</button>
            </div>
        </modal>
        <button type="button" class="btn btn-link add_o_contact" v-on:click="openContactModal = true" >
          <i class="fa fa-fw fa-plus"></i>Add ...
        </button>

            <div class="mt-1 mb-1">
              Description
              <br />
              <div class="mt-1" data-placeholder="Write a description...">
               <markdown-text-edit v-model="item.description" v-on:input="updateOpportunity" placeholder="Write a description" ></markdown-text-edit>
              </div>
              <br />
            </div>
      </div>
      <to-do
        :activities="activities"
        :companyUsers="company_users"
        :contact="contact"
        :opportunity="opportunity"
        :company="company"
        :timeZone="time_zone"
      >
        <comment_form slot="comment-form" :contact="contact" :opportunity="opportunity" :user_image="user_image" />
        <timeline_events
          slot="timeline-events"
          :events="events"

          />
      </to-do>

    </div>
  </div>

</template>

<script>
  import InlineEdit from '../inline-common-edit.vue';
  import ToDo from './to-do-edit.vue';
  import CommentForm from './comment-form.vue';
  import TimelineEvents from './timeline-events.vue';
  import MarkdownTextEdit from '../markdown-textedit.vue';

  export default {
    props: [
      'socket', 'channel',
      'contact', 'time_zone', 'current_user_id',
      'opportunity', 'company',
      'opportunities',
      'company_users',
      'organization',
      'user_image'
    ],
    data(){
      return {
        openContactModal: false,
        allowUpdate: true,
        item: this.opportunity,
        items: this.opportunities,
        contacts: this.opportunityContacts,
        boardColumns: [],
        board: {},
        opportunityChannel: null,
        activities: [],
        events: [],
        opportunityContacts: []

      };
    },
    methods: {
      browse(){
        this.leaveChannel();
        this.$emit('browse');
      },
      addContact(){
        let url = '/api/v2/contact';
        let data = {
          name: this.NewContactName,
          userId: this.opportunity.user_id
        };
        if (this.company) {
          data['company_id'] = this.company.id;
        }
        if (this.organization) {
          data['organization_id'] = this.organization.id;
        }
        this.$http.post(url, { contact: data }).then(resp => {
          let urlOpp = '/api/v2/opportunity/'+ this.opportunity.id;
          let contactIds = [];
          this.opportunityContacts.forEach(function(item) {
            contactIds.push(item.id);
          });
          contactIds.push(resp.data.data.id);
          this.$http.put(urlOpp,{ opportunity: { contactIds: contactIds } });
        });

        this.NewContactName = '';
        this.openContactModal = false;
      },

      archiveOpportunity() {
        let url = '/api/v2/opportunity/' + this.item.id;
        this.$http.put(url, { opportunity: { status: '1'} });
      },

      updateOpportunity(){
        if (this.allowUpdate) {
          let url = '/api/v2/opportunity/' + this.item.id;
          this.$http.put(url, { opportunity: this.item });
        }
      },

      refreshOpportunity(payload){
        if (payload.activities) {
          this.$data.activities = payload.activities;
        }
        if (payload.board) {
          this.$data.board = payload.board;
          this.$data.boardColumns = payload.board_columns;
        }

        if (payload.events) {
          this.$data.events = payload.events;
        }

        if (payload.opportunity) {
          this.$data.item = payload.opportunity;
        }
        if (payload.opportunity_contacts) {
          this.$data.opportunityContacts = payload.opportunity_contacts;
        }
        this.allowUpdate = true;
      },

      subscribe() {

        this.opportunityChannel.on('opportunity:closed', payload => {
          if (payload.opportunity) {
            let itemIndex = this.opportunities.findIndex(function(item){
              return item.id === parseInt(payload.opportunity.id);
            });
            this.$data.items.splice(itemIndex,1);

            if (this.$data.items.length === 0) {
              this.clearOpportunity();
            } else if (this.$data.item.id === parseInt(payload.opportunity.id)) {
              this.setOpportunity(this.$data.items[0]);
            }
            this.$emit('browse');
          }
        });
        this.opportunityChannel.on('opportunity:updated', payload => {
          if (payload.opportunity) {
            this.$data.item = payload.opportunity;
            this.$data.opportunityContacts = payload.opportunity_contacts;

            let itemIndex = this.opportunities.findIndex(function(item){
              return item.id === parseInt(payload.opportunity.id);
            });

            this.$data.items.splice(itemIndex, 1, payload.opportunity);
          }
          if (payload.board) {
            this.$data.board = payload.board;
            this.$data.boardColumns = payload.board_columns;
          }
        });


        this.opportunityChannel.on('activity:created', payload => {
          this.$data.activities.unshift(payload.activity);
        });

        this.opportunityChannel.on('activity:deleted', payload => {
          let itemIndex = this.$data.activities.findIndex(function(item){
            return item.id === parseInt(payload.activity_id);
          });
          this.$data.activities.splice(itemIndex, 1);
        });

        this.opportunityChannel.on('activity:updated', payload => {
          let itemIndex = this.$data.activities.findIndex(function(item){
            return item.id === parseInt(payload.activity.id);
          });
          this.$data.activities.splice(itemIndex, 1, payload.activity);
        });

        this.channel.on('timeline_event:created', payload => {
          this.$data.events.unshift(payload.event);
        });
      },
      leaveChannel() {
        if (this.$data.opportunityChannel) {
          this.$data.opportunityChannel.leave();
        }
      },
      initChannel(){
        let channelTopic = 'opportunities:' + this.opportunity.id;
        if (this.opportunity.id) {
          this.$http.get('/api/v2/opportunity/' + this.opportunity.id).then(resp => {
            this.refreshOpportunity(resp.data);
          });
        }
        this.opportunityChannel = this.socket.channels.find(function(item){
          return channelTopic === item.topic;
        });

        if (this.opportunityChannel) {
          this.subscribe();
        } else {
          this.opportunityChannel = this.socket.channel(channelTopic, {});
          this.subscribe();
          this.opportunityChannel.join()
                .receive('ok', resp => { })
                .receive('error', resp => {  });
        }
      },

      clearOpportunity() {
        this.allowUpdate = false;
        this.$data.item = null;
        this.leaveChannel();
      },
      setOpportunity(opp) {
        this.allowUpdate = false;
        this.$data.item = opp;
        this.initChannel();
      }
    },
    watch: {
      opportunity() {
        this.allowUpdate = false;
        this.$data.item = this.opportunity;

        if (this.opportunity){
          this.initChannel();
        } else { this.leaveChannel(); }
      }
    },
    components: {
      'inline-edit': InlineEdit,
      'to-do': ToDo,
      'comment_form': CommentForm,
      'timeline_events': TimelineEvents,
      'markdown-text-edit': MarkdownTextEdit,
      'v-select': vSelect.VueSelect,
      'modal': VueStrap.modal
    },


    mounted() {
      this.initChannel();
    }

  };
</script>

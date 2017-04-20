<template>
  <div class="contact-edit">
    <div style=""  >
      <!-- Main content -->
      <section>
        <div class="row">
          <div class="col-md-12">
            <table style="width:100%;background-color: #edf0f5;">
              <tr>
                <td style="width:50%;padding:20px;vertical-align: top;padding-right:0px;">
                  <profile-edit
                    :contact="contact"
                    :tags="tags"
                    v-on:remove="deleteContact" />
                </td>

                <td style="width:50%;padding:20px;vertical-align: top;">
                  <organization-edit
                    :organization="organization"
                    :contact="contact"
                    :company="company"
                    >
                   </organization-edit>
                </td>
              </tr>
            </table>
          </div>
        </div>
        <div class="row" v-if="browseOpportunities">
          <div class="col-md-12">
          <div style="padding:15px;background-color:#EDF0F5;">
              <div v-for="opp in opportunities" v-on:click="changeOpportunity(opp)" class="opportunity-tags">
                {{opp.name}}
              </div>
              <button v-show="!showAddCard" v-on:click="showAddCard=true" type="button" class="btn btn-link show-add-card-form">
               <i class="fa fa-fw fa-plus"></i>Create a card
              </button>
              <div v-show="showAddCard">
                Create a card into the board:
                <select v-model="newBoard">
                  <option v-for="board in boards" :value="board">{{board.name}}</option>
                </select>
                &nbsp;&nbsp;
                <button type="button" v-on:click="addNewCard" >Add</button>
              </div>
            </div>
          </div>
        </div>

        <div class="row" v-if="opportunity && !browseOpportunities">

          <opportunity-edit
            ref="opportunityEdit"
            :time_zone="timeZone"
            :organization="organization"
            :contact="contact"
            :company="company"
            :company_users="companyUsers"
            :opportunity="opportunity"
            :opportunities="opportunities"
            :user_image="userImage"
            v-on:browse="browseOpportunities = true"
            :socket="socket"
            :channel="channel"
            />

        </div>
      </section>
    </div>
  </div>
</template>

<script>
import {Socket, Presence} from 'phoenix';
import InlineEdit from '../inline-common-edit.vue';
import ProfileEdit from './profile-edit.vue';
import OrganizationEdit from './organization-edit.vue';
import OpportunityEdit from './opportunity-edit.vue';

export default {

  props: ['contact_id', 'opportunity_id'],
  data() {
    return {
      showAddCard: false,
      socket: null,
      channel: null,
      contact: { },
      company: {},
      companyUsers: [],
      organization: null,
      opportunity: null,
      opportunities: [],
      tags: [],
      activities: [],
      events: [],
      board: null,
      boards: [],
      boardColumns: [],
      newBoard: null,
      browseOpportunities: true,
      timeZone: null,
      userImage: null
    };
  },
  watch: {
    'contact_id': function() {
      this.initConn(true);
    }
  },
  components: {
    'inline-edit': InlineEdit,
    'profile-edit': ProfileEdit,
    'organization-edit': OrganizationEdit,
    'opportunity-edit': OpportunityEdit

  },
  methods: {
    changeOpportunity(opp) {
      this.browseOpportunities = false;
      this.opportunity = opp;
      return false;
    },
    addNewCard() {
      var url = '/api/v2/opportunity/';
      this.$http.post(url,
        { opportunity: {
          mainContactId: this.contact.id,
          contactIds: [this.contact.id],
          companyId: this.company.id,
          name: '',
          boardId: this.newBoard.id,
          boardColumnId: this.newBoard.board_columns[0].id
        } });
      this.newBoard = null;
      this.showAddCard = false;
    },

    deleteContact: function(){
      console.log('delete contact');
    },

    setAuthToken(){
      var vm = this;
      localStorage.setItem('auth_token', document.querySelector('meta[name="guardian_token"]').content);
      Vue.http.headers.common['Authorization'] = 'Bearer ' + localStorage.getItem('auth_token');
      if (vm.contact_id) {
        vm.initConn();
      }
    },
    refreshContact(payload) {
      if (payload.contact) {
        this.contact = payload.contact;
      }

      if (payload.boards) {
        this.boards = payload.boards;
      }

      if (payload.opportunities) {
        this.opportunities = payload.opportunities;
        if (this.opportunity_id) {
          let opp = payload.opportunities.find((item) => {
            return item.id === this.opportunity_id;
          });
          if (opp) { this.changeOpportunity(opp); }
        } else if (this.opportunities.length === 1) {
          this.changeOpportunity(this.opportunities[0]);
        }
      }

      if (payload.company) {
        this.company = payload.company;
      }
      if (payload.company_users) {
        this.companyUsers = payload.company_users;
      }
      if (payload.tags) {
        this.tags = payload.tags;
      }
      if (payload.organization) {
        if (payload.organization['id']) {
          this.organization = payload.organization;
        } else {
          this.organization = null;
        }
      }

    },

    loadContact() {
      if (this.contact_id) {
        this.$http.get('/api/v2/contact/' + this.contact_id).then(resp => {
          this.refreshContact(resp.data);
        });
      }
    },

    initConn(reset) {
      this.socket = new Socket('/socket', {params: { token: localStorage.getItem('auth_token') }});
      this.socket.connect();
      this.channel = this.socket.channel('contacts:' + this.contact_id, {});

      this.channel.join()
                .receive('ok', resp => {  })
                .receive('error', resp => { console.log('Unable to join', resp); });

      if (reset) {
        this.opportunities = [];
        this.opportunity = null;
        this.company = null;
        this.tags = [];
        this.organization = null;
        this.browseOpportunities = true;
      }

      this.channel.on('update', payload => {
        this.refreshContact(payload);
      });

      this.channel.on('opportunity:created', payload => {
        if (payload.opportunity) {
          this.opportunities.push(payload.opportunity);
          this.opportunity || (this.opportunity = payload.opportunity);
        }
      });

      this.loadContact();
    }
  },
  mounted(){
    this.timeZone = document.querySelector('meta[name="time_zone"]').content;
    this.userImage = document.querySelector('meta[name="user_image"]').content;
    this.setAuthToken();
  }

};
</script>

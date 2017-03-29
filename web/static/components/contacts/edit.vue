<template>
  <div class="contact-edit">
    <div style="max-width:800px;margin: 0px auto;"  >
      <!-- Main content -->
      <section class="content" style="margin-top:20px;">
        <div class="row">
          <div class="col-md-12">
            <table style="width:100%;background-color:white;">
              <tr>
                <td style="width:50%;padding:20px;vertical-align: top;">
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
                    <li slot="menu"><a href="#"  v-on:click="deleteContact">Delete Contact</a></li>
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
            :time_zone="time_zone"
            :current_user_id="current_user_id"
            :organization="organization"
            :contact="contact"
            :company="company"
            :company_users="companyUsers"
            :opportunity="opportunity"
            :opportunities="opportunities"
            :user_image="user_image"
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
  props: ['contact_id', 'current_user_id', 'time_zone', 'user_image'],
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
      browseOpportunities: true

    };
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
      vm.connectToSocket();
    },

    connectToSocket() {
      this.socket = new Socket('/socket', {params: { token: localStorage.getItem('auth_token') }});
      this.socket.connect();
      this.channel = this.socket.channel('contacts:' + this.contact_id, {});

      this.channel.join()
                .receive('ok', resp => {
                  this.channel.push('load_state');
                })
                .receive('error', resp => { console.log('Unable to join', resp); });


      this.channel.on('opportunity:created', payload => {
        if (payload.opportunity) {
          this.opportunities.push(payload.opportunity);
          this.opportunity || (this.opportunity = payload.opportunity);
        }
      });

      this.channel.on('state', payload => {
        this.contact = payload.contact;
        if (payload.boards) {
          this.boards = payload.boards;
        }

        if (payload.opportunities) {
          this.opportunities = payload.opportunities;
        }
        if (payload.company) {
          this.company = payload.company;
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

      });
    }
  },
  mounted(){
    this.setAuthToken();

  }
};
</script>

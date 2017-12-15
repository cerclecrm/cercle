<template>
  <div class="inbox-list">
    <!-- Main content -->
    <section class="content">

      <div class="row" v-if="emptyList">
        <div class="col-xs-12">
          <p class="lead text-info"><strong>Nothing to do, go to the park!</strong></p>
        </div>
      </div>

      <div class="row" v-if="activities.length > 0">
        <div class="col-xs-12">
          <h3>Tasks with due date</h3>
        </div>
      </div>

      <div class="row activity-list" >
        <div class="col-xs-12">
          <div v-for="(activities_list, card_name) in groupBy(activities, 'card')" class="panel">
            <div class="panel-heading">
              <h5>{{card_name}}</h5>
            </div>
            <div class="panel-body">
              <div class="nav-tabs-custom ">
                <table class="table table-responsive table-hover">
                  <tbody>
                    <tr
                      is="activity-item"
                      v-for="item in activities_list"
                      :item="item"
                      :time_zone="timeZone"
                      :key="item.id"
                      :class="itemClass(item)"
                      v-on:done="doneTask(item)"
                      v-on:card-show="cardShow(item.cardId)"
                      ></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="row" v-if="cards.length > 0">
        <div class="col-xs-12">
          <h3 class="pull-left">Cards assigned to me</h3>
          <label class="assigned-user pull-right">
            <select-member
              v-model.number="assignUserId"
              :users="companyUsers"
              @change="changeAssignedUser"/>
          </label>
        </div>
      </div>

      <div class="row card-list" >
        <div class="col-xs-12">

          <div v-for="(card_list, board_name) in cardItems" class="panel">
            <div class="panel-heading">
              <h4>{{board_name}}</h4>
            </div>
            <div class="panel-body">
              <div class="nav-tabs-custom">
                <table class="table table-responsive table-hover">
                  <tbody>
                    <tr
                      is="card-item"
                      v-for="card in card_list"
                      :item="card"
                      :key="card.id"
                      v-on:card-show="cardShow(card.id)"
                      ></tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script>
  import {Socket, Presence} from 'phoenix';
  import InlineEdit from '../shared/inline-common-edit.vue';
  import CardShow from '../cards/show.vue';
  import ActivityItem from './item.vue';
  import CardItem from './card-item.vue';
  import SelectMember from '../shared/select-member.vue';

  export default {
    data() {
      return {
        timeZone: null,
        contact: {},
        card: {},
        activities: [],
        activitiesOverdue: [],
        activitiesLater: [],
        activitiesToday: [],
        socket: null,
        channel: null,
        userId: null,
        assignUserId: null,
        cards: [],
        companyUsers: []
      };
    },
    computed: {
      emptyList() {
        return this.cards.length === 0 && this.activities.length === 0;
      },
      cardItems() {
        return this.groupBy(
          this.$_.orderBy(
            this.cards, (t) => { return this.$_.get(t, ['boardColumn', 'order']); }, ['asc']
          ), 'board');
      }
    },
    components: {
      'inline-edit': InlineEdit,
      'modal': VueStrap.modal,
      'card-show': CardShow,
      'activity-item': ActivityItem,
      'card-item': CardItem,
      'select-member': SelectMember
    },
    methods: {
      changeAssignedUser() {
        let cardIds = this.$_.map(this.cards, 'id');
        let url = '/api/v2/company/' + Vue.currentUser.companyId + '/card/reassign';
        this.$http.put(
          url, { userId: this.assignUserId, cardIds: cardIds }
        ).then(resp => { this.cards = [];  });
      },
      groupBy(list, prop) {
        return list.reduce(function(groups, item) {
          let val = item[prop].name;
          groups[val] = groups[val] || [];
          groups[val].push(item);
          return groups;
        }, {});
      },
      doneTask(task) {
        this.deleteItem(this.activities, task.id);
      },
      itemClass(item) {
        if (Moment(item.due_date).isSame(new Date(), 'day')) {
          return 'today';
        } else {
          return 'other';
        }
      },
      cardShow(cardId) {
        this.card = { id: cardId };
        this.$glmodal.$emit(
         'open', {
           view: 'card-show', class: 'card-modal', data: { 'cardId': cardId }
         });

      },
      initConn() {
        let activityUrl = '/api/v2/company/' + Vue.currentUser.companyId + '/activity';
        this.$http.get(activityUrl, { params: { userId: Vue.currentUser.userId }}).then(resp => {
          this.activities = resp.data.activities;
        });

        let cardUrl = '/api/v2/company/' + Vue.currentUser.companyId + '/card';
        this.$http.get(cardUrl, { params: { userId: Vue.currentUser.userId }}).then(resp => {
          this.cards = resp.data.data;
        });

        this.socket = new Socket('/socket', {params: { token: localStorage.getItem('auth_token') }});
        this.socket.connect();
        this.channel = this.socket.channel('users:' + this.userId, {});

        this.channel.join()
              .receive('ok', resp => {  })
              .receive('error', resp => { console.log('Unable to join', resp); });

        this.channel.on('activity:deleted', payload => {
          let _payload = this.camelCaseKeys(payload);
          this.deleteItem(this.activities, _payload.activityId);
        });

        this.channel.on('activity:created', payload => {
          let _payload = this.camelCaseKeys(payload);
          this.$data.activities.push(_payload.activity);
        });

        this.channel.on('activity:updated', payload => {
          let _payload = this.camelCaseKeys(payload);
          this.updateItem(this.activities, _payload.activity);
        });
      },
      updateItem(collection, data) {
        let itemIndex = collection.findIndex(function(item){
          return item.id === parseInt(data.id);
        });
        if (itemIndex >= 0) {
          collection.splice(itemIndex, 1, data);
        } else {
          this.$data.activities.push(data);
        }
      },
      deleteItem(collection, id) {
        let itemIndex = collection.findIndex(function(item){
          return item.id === parseInt(id);
        });
        if (itemIndex >= 0) { collection.splice(itemIndex, 1); }
      }
    },

    mounted() {
      this.timeZone = Vue.currentUser.timeZone;
      this.userId = Vue.currentUser.userId;
      this.assignUserId = Vue.currentUser.userId;
      this.initConn();
      let url = '/api/v2/company/' + Vue.currentUser.companyId + '/company/users';
      this.$http.get(url).then(resp => {
        this.companyUsers = resp.data.users;
      });
    }
  };
</script>
<style lang="sass">
  .inbox-list {
    .assigned-user {
      background-color: #dfe1e4;
      padding: 4px 15px 4px 15px;
      margin-top: 12px;
    }
    .activity-list {
      .panel {
        margin-bottom: 5px;
        .panel-heading {
          padding: 5px 10px;
        }
      }
    }
    .card-list {
      .panel {
        margin-bottom: 5px;
        .panel-heading {
          padding: 5px 10px;
        }
      }
    }
  }
</style>

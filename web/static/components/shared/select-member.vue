<template>
  <span v-on-click-outside='cancel'>
    <span v-on:click="showModal" v-if="!inline" :class="buttonClass">
      <slot>
        <span v-if="currentMember">
          <img :src="currentMember.profileImageUrl" class='profile-image' :title="currentMember.fullName" />
          <span v-if="!displayShort">{{currentMember.fullName}}</span>
        </span>
        <span v-else>{{ placeholder }}</span>
      </slot>
    </span>

    <div v-show="editMode || inline" class='input-modal'>
      <div class='modal-header clearfix'>
        <span>Members</span>
        <a class='close pull-right' v-on:click='cancel' v-if="!inline">×</a>
      </div>

      <div class='modal-body'>
        <ul class='users-list'>
          <li :class='memberClass(user)' v-for="user in users" @click="toggleMemberSelection(user)">
            <img :src="user.profileImageUrl" class='profile-image' />
            {{ user.fullName }}
            <i class="fa fa-check" v-if="user.id == v" />
          </li>
        </ul>
      </div>
    </div>
  </span>
</template>

<script>
export default {
  props: ['value', 'users', 'displayShort', 'placeholder', 'buttonClass', 'inline', 'disableUnselect'],
  data() {
    return {
      v: this.value,
      editMode: false
    };
  },
  computed: {
    currentMember() {
      return this.$_.find(this.users, {'id' : parseInt(this.v)});
    }
  },
  watch: {
    'value': function() { this.v = this.value; }
  },
  methods: {
    memberClass(user) {
      let userId = this.v;
      if(userId === user.id)
        return 'active';
    },
    showModal: function() {
      this.editMode = true;
    },
    toggleMemberSelection: function(user) {
      if(this.v === user.id && !this.disableUnselect) {
        this.$emit('input', '');
        this.$emit('change', '');
      } else {
        this.$emit('input', user.id);
        this.$emit('change', user.id);
      }
    },
    cancel: function() {
      this.editMode = false;
    }
  }
};
</script>

<style lang="sass" scoped>
  .inline-mode {
    .input-modal {
      position: static;
    }
  }

  .modal-body {
    ul.users-list {
      li {
        width: 100%;
        float: none;
        text-align: left;
        cursor: pointer;
        padding: 5px 10px;
        border-radius: 0;

        &:hover {
          background-color: lightblue;
        }

        &.active {
          background-color: #298FCA;
          color: white;
        }
      }
    }

    .profile-image {
      max-width: 20px;
      max-height: 20px;
    }
  }
</style>

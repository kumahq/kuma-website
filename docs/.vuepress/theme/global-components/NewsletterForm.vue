<template>
  <div class="form-wrapper">
    <form class="form-horizontal" @submit.prevent="submitForm">

      <!-- hidden fields -->
      <input v-model="formData.oid" type="hidden" name="oid" value="00D41000000WdaQ">
      <input v-model="formData.retURL" type="hidden" name="retURL" value="http://go.konghq.com/l/392112/2019-09-03/bjz6yv">
      <input v-model="formData.Lead_Source_Detail" type="hidden" name="Lead_Source_Detail" id="Lead_Source_Detail__c" value="Kuma Email List Signup">
      <input v-model="formData.lead_source" type="hidden" name="lead_source" id="lead_source" value="Web">
      <input v-model="formData.Lead_Record_Type" type="hidden" name="Lead_Record_Type" id="RecordType" value="0121K000001QQgX">
      <input v-model="formData.utm_source" type="hidden" name="utm_source" id="utm_source__c" value="">
      <input v-model="formData.utm_ad_group" type="hidden" name="utm_ad_group" id="utm_ad_group__c" value="">
      <input v-model="formData.utm_campaign" type="hidden" name="utm_campaign" id="utm_campaign__c" value="">
      <input v-model="formData.utm_content" type="hidden" name="utm_content" id="utm_content__c" value="">
      <input v-model="formData.utm_medium" type="hidden" name="utm_medium" id="utm_medium__c" value="">
      <input v-model="formData.utm_term" type="hidden" name="utm_term" id="utm_term__c" value="">

      <!-- debugging -->
      <input v-model="formData.debug" type="hidden" name="debug" value="1">
      <input v-model="formData.debugEmail" type="hidden" name="debugEmail" value="maria@konghq.com">

      <!-- user fields -->
      <label for="email" class="sr-only">Email</label>
      <input v-model="formData.email" id="email" maxlength="80" name="email" size="20" type="email" />

      <button type="submit" class="btn btn--bright">
        Join Newsletter
      </button>
    </form>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  data() {
    return {

      formData: {
        // hidden fields
        oid: '00D41000000WdaQ',
        retURL: 'http://go.konghq.com/l/392112/2019-09-03/bjz6yv',
        Lead_Source_Detail: 'Kuma Email List Signup',
        lead_source: 'Web',
        Lead_Record_Type: '0121K000001QQgX',
        utm_source: '',
        utm_ad_group: '',
        utm_campaign: '',
        utm_content: '',
        utm_medium: '',
        utm_term: '',

        // debug fields
        debug: 1,
        debugEmail: 'maria@konghq.com',

        // user fields
        email: ''
      }
    }
  },
  methods: {
    submitForm(ev) {
      // console.log(this.formData)
      axios.post( 'https://webto.salesforce.com/servlet/servlet.WebToLead?encoding=UTF-8', {
        crossDomain: true,
        data: JSON.stringify(this.formData),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      })
      .then(res => {
        console.log(res.status, res.data)
      })
      .catch(err => {
        console.error(err)
      })
    }
  }
}
</script>
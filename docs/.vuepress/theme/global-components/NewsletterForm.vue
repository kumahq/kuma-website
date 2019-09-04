<template>
  <div class="form-wrapper">

    <!-- 
      This form uses Web-To-Lead by Salesforce,
      which is a bit dated.
      
      @todo Find a solution that allows us to use
      modern form handlers and axios or fetch.
      The endpoint is currently not setup for
      this approach and will not pass data
      properly.
     -->

    <form class="form-horizontal" action="https://webto.salesforce.com/servlet/servlet.WebToLead?encoding=UTF-8" method="POST">
      <input type="hidden" name="oid" value="00D41000000WdaQ">
      <input type="hidden" name="retURL" value="http://go.konghq.com/l/392112/2019-09-03/bjz6yv">
      <input type="hidden" name="Lead_Source_Detail" id="Lead_Source_Detail__c" value="Kuma Email List Signup">
      <input type="hidden" name="lead_source" id="lead_source" value="Web">
      <input type="hidden" name="Lead_Record_Type" id="RecordType" value="0121K000001QQgX">
      <input type="hidden" name="utm_source" id="utm_source__c" value="">
      <input type="hidden" name="utm_ad_group" id="utm_ad_group__c" value="">
      <input type="hidden" name="utm_campaign" id="utm_campaign__c" value="">
      <input type="hidden" name="utm_content" id="utm_content__c" value="">
      <input type="hidden" name="utm_medium" id="utm_medium__c" value="">
      <input type="hidden" name="utm_term" id="utm_term__c" value="">

      <!-- debugging only - hide for production -->
      <input type="hidden" name="debug" value="1">
      <input type="hidden" name="debugEmail" value="maria@konghq.com">

      <!-- user fields -->
      <label for="email" class="sr-only">Email</label>
      <input  id="email" maxlength="80" name="email" size="20" type="text" />

      <button type="submit" name="submit" class="btn btn--bright">
        Join Newsletter
      </button>
    </form>

  </div>
</template>

<script>
export default {}
</script>
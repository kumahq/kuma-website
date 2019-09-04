<template>
  <div class="page-container page-container--community">

    <header v-if="$page.frontmatter.title" class="page-header text-center bg-gradient">
      <div class="inner">
        <h1>{{ $page.frontmatter.title }}</h1>
        <p v-if="$page.frontmatter.title" class="page-sub-title">{{ $page.frontmatter.subTitle }}</p>
      </div>
      <!-- .inner -->
    </header>
    <!-- .page-header -->

    <div class="inner flex flex-wrap -mx-4">

      <div class="w-full sm:w-1/2 px-4">

        <div class="flex flex-wrap -mx-2">

          <div class="tower-wrap w-full lg:w-1/2 px-2">
            
            <div class="tower">
              <div class="tower__header">
                <h3>Community</h3>
              </div>
              <div class="tower__content">
                <ul class="tower__list">
                  <li class="tower__list-title tower__list-title--muted">
                    <h4>Basic Features</h4>
                  </li>
                  <li>{{ getSiteData.title }} Core</li>
                  <li>{{ getSiteData.title }} OSS Policies</li>
                  <li class="tower__list-title tower__list-title--positive tower__footer-item">Free</li>
                </ul>
              </div>
            </div>
            <!-- .tower -->
            
          </div>

          <div class="tower-wrap w-full lg:w-1/2 px-2">
            
            <div class="tower">
              <div class="tower__header">
                <h3>Enterprise</h3>
              </div>
              <div class="tower__content">
                <ul class="tower__list">
                  <li class="tower__list-title tower__list-title--muted">
                    <h4>Basic Features</h4>
                  </li>
                  <li>{{ getSiteData.title }} Core</li>
                  <li>{{ getSiteData.title }} OSS Policies</li>
                  <li class="tower__list-title tower__list-title--focus">
                    <h4>Enterprise Support</h4>
                  </li>
                  <li class="tower__focus-item">Email Support</li>
                  <li class="tower__focus-item">Phone Support</li>
                  <li class="tower__focus-item">Initial Setup and Upgrade Path</li>
                  <li class="tower__focus-item">Org Architectural Review</li>
                  <li class="tower__focus-item">Hot fixes and emergency patches</li>
                  <li class="tower__focus-item">Custom Policies</li>
                  <li class="tower__focus-item">Integration with Kong Enterprise</li>
                  <li class="tower__list-title tower__list-title--neutral">
                    <span class="desktop">Fill out form on the right</span>
                    <span class="mobile">Fill out form below</span>
                  </li>
                </ul>
              </div>
            </div>
            <!-- .tower -->

          </div>

        </div>

      </div>

      <div class="demo-request-form w-full sm:w-1/2 px-4">
        <!-- 
          This form uses Web-To-Lead by Salesforce,
          which is a bit dated.
          
          @todo Find a solution that allows us to use
          modern form handlers and axios or fetch.
          The endpoint is currently not setup for
          this approach and will not pass data
          properly.
        -->
        <form action="https://webto.salesforce.com/servlet/servlet.WebToLead?encoding=UTF-8" method="POST" class="sticky">
          <input type="hidden" name="oid" value="00D41000000WdaQ">
          <input type="hidden" name="retURL" value="http://go.konghq.com/l/392112/2019-09-03/bjz6ys">
          <input type="hidden" name="Lead_Source_Detail" id="Lead_Source_Detail__c" value="Kuma Request a Demo">
          <input type="hidden" name="lead_source" id="lead_source" value="Web">
          <input type="hidden" name="Lead_Record_Type" id="RecordType" value="0121K000001QQgX">
          <input type="hidden" name="utm_source" id="utm_source__c" value="">
          <input type="hidden" name="utm_ad_group" id="utm_ad_group__c" value="">
          <input type="hidden" name="utm_campaign" id="utm_campaign__c" value="">
          <input type="hidden" name="utm_content" id="utm_content__c" value="">
          <input type="hidden" name="utm_medium" id="utm_medium__c" value="">
          <input type="hidden" name="utm_term" id="utm_term__c" value="">

          <!-- debugging only -->
          <input type="hidden" name="debug" value="1">
          <input type="hidden" name="debugEmail" value="maria@konghq.com">

          <div class="flex flex-wrap -mx-4">   
            <div class="w-full md:w-1/2 px-4">
              <label for="first_name">First Name</label>
              <input  id="first_name" maxlength="40" name="first_name" size="20" type="text" />
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="last_name">Last Name</label>
              <input  id="last_name" maxlength="80" name="last_name" size="20" type="text" />
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="email">Email</label>
              <input id="email" maxlength="80" name="email" size="20" type="email" />
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="company">Company</label>
              <input id="company" maxlength="40" name="company" size="20" type="text" />
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="phone">Phone</label>
              <input id="phone" maxlength="40" name="phone" size="20" type="text" />
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="title">Title</label>
              <input id="title" maxlength="40" name="title" size="20" type="text" />
            </div>
            <div class="w-full px-4">
              <label for="00N4100000PN0Nm">How can we help you?</label>
              <textarea id="00N4100000PN0Nm" name="00N4100000PN0Nm" rows="3" type="text" wrap="soft"></textarea>
            </div>
            <div class="w-full px-4 mt-4">
              <button type="submit" name="submit" class="btn btn--bright btn--spaced btn--block">
                Request Demo
              </button>
            </div>
          </div>
        </form>
      </div>

    </div>
    <!-- .inner -->
  
  </div>
</template>

<script>
export default {
  
}
</script>

<style lang="scss">

</style>
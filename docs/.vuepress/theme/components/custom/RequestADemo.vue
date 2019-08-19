<template>
  <div class="page-container page-container--community">

    <header class="page-header text-center bg-gradient">
      <div class="inner">
        <h1>Transform your Enterprise</h1>
        <p class="page-sub-title">Learn how {{ getSiteData.title }} can help your business and improve your applications reliability.</p>
      </div>
      <!-- .inner -->
    </header>
    <!-- .page-header -->

    <div class="inner flex flex-wrap -mx-4">

      <div class="w-full sm:w-1/2 px-4">

        <div class="flex flex-wrap -mx-2">
          <div class="w-full md:w-1/2 px-2">
            <p>Lorem ipsum dolor sit amet consectetur adipisicing elit. Velit veniam ullam, suscipit esse explicabo impedit, quis ad aut, minima veritatis nobis nihil eos rerum reiciendis. Minima nam maxime fuga iusto.</p>
          </div>
          <div class="w-full md:w-1/2 px-2">
            <p>Lorem ipsum dolor sit amet consectetur adipisicing elit. Unde consequuntur eum impedit aperiam non eaque libero atque molestias doloremque, nesciunt ea rem ratione placeat sint dignissimos vitae dolorem fuga sunt.</p>
          </div>
        </div>

      </div>

      <div class="w-full sm:w-1/2 px-4">
        <form action="">
          <div class="flex flex-wrap -mx-4">
            <div class="w-full md:w-1/2 px-4">
              <label for="input-firstname">First Name</label>
              <input type="text" name="firstname" id="input-firstname">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-lastname">Last Name</label>
              <input type="text" name="lastname" id="input-lastname">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-workemail">Work Email</label>
              <input type="text" name="workemail" id="input-workemail">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-phone">Phone</label>
              <input type="text" name="phone" id="input-phone">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-jobtitle">Job Title</label>
              <input type="text" name="jobtitle" id="input-jobtitle">
            </div>
            <div class="w-full md:w-1/2 px-4">
              <label for="input-companyname">Company Name</label>
              <input type="text" name="companyname" id="input-companyname">
            </div>
            <div class="w-full px-4">
              <label for="input-comments">How can we help you?</label>
              <textarea name="comments" id="input-comments"></textarea>
            </div>
            <div class="w-full px-4 mt-4">
              <button class="btn btn--bright btn--spaced btn--block">Request Demo</button>
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
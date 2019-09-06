<template>
  <div class="form-wrapper">

    <!-- 
      @todo 
      wire this form up to a Google spreadsheet like
      the Request A Demo form.
     -->

    <form class="form-horizontal">
      <label for="email" class="sr-only">Email</label>
      <input  id="email" name="email" type="email" />
      <button type="submit" name="submit" class="btn btn--bright">
        Join Newsletter
      </button>
    </form>

  </div>
</template>

<script>
export default {}
</script>
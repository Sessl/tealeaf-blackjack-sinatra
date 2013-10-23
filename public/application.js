$(document).ready(function(){
      $(document).on("click", "form#hit_form input", function(){
            alert("player hits!");

            $.ajax({
                  type: "POST",
                  url: "/game/player/hit"

            }).done(function(msg){
                  $("#game").replaceWith(msg);
            });
            
            return false;
      });
});
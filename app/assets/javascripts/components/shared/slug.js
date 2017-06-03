import $ from 'jquery';
import { transliterate as tr, slugify } from 'transliteration';

let generateSlug = (title) => {
  let slug;

  if (!title) { return ''; }

  slug = slugify(title);

  if (!slug) { slug = '-'; }

  return slug;
}

$(document).on('turbolinks:load', () => {
  $('.js-title').on('change paste keyup click', () => {
    let title = $('.js-title').val();
    $('.js-slug').val(generateSlug(title));
  });
})
